import Foundation
import ModelRegistry
import HuggingFaceCache
@preconcurrency import StudioServices
import LocalLLMClient
import LocalLLMClientLlama

/// Real language model service using llama.cpp via the LocalLLMClient library.
/// No subprocess -- direct library calls with the InferenceRunner pattern for thread safety.
public actor LlamaCppLanguageModelService: @preconcurrency LanguageModelServing {
    private let resolver: ModelResolver
    private var runner: InferenceRunner?
    private var isLoaded = false
    private nonisolated(unsafe) var isCancelled = false
    private var currentModelPath: String?

    // Diagnostics
    private var loadStartTime: Date?
    private var loadDuration: TimeInterval = 0
    public private(set) var lastTokensPerSecond: Double = 0
    public private(set) var lastGenerationDuration: TimeInterval = 0
    public private(set) var lastTokenCount: Int = 0

    public init(resolver: ModelResolver) {
        self.resolver = resolver
    }

    /// Load a GGUF model from the Hugging Face cache.
    public func load(_ specification: HuggingFaceModelSpecification) async throws {
        loadStartTime = Date()

        let resolved = try await resolver.resolve(
            specification,
            policy: .online
        )

        // Find the GGUF file
        let ggufFiles = resolved.modelFiles.filter {
            $0.pathExtension.lowercased() == "gguf"
        }
        guard let ggufFile = ggufFiles.first else {
            throw LlamaCppBackendError.ggufFileNotFound
        }

        currentModelPath = ggufFile.path
        runner = InferenceRunner(modelURL: ggufFile)
        isLoaded = true

        if let start = loadStartTime {
            loadDuration = Date().timeIntervalSince(start)
        }
    }

    // MARK: - LanguageModelServing

    public func generate(
        prompt: String,
        schemaJSON: String?,
        temperature: Double,
        seed: UInt64?
    ) async throws -> AsyncThrowingStream<String, Error> {
        guard self.runner != nil, isLoaded else {
            throw LlamaCppBackendError.modelNotLoaded
        }

        isCancelled = false
        let startTime = Date()
        let counter = TokenCounter()

        let finalPrompt: String
        if let schema = schemaJSON {
            finalPrompt = """
            \(prompt)

            You MUST respond with valid JSON matching this schema:
            \(schema)

            Response (JSON only, no markdown):
            """
        } else {
            finalPrompt = prompt
        }

        return .taskBacked { continuation in
            try await self.runner?.infer(prompt: finalPrompt) { token in
                if self.isCancelled { return }
                counter.count += 1
                continuation.yield(token)
            }
            let elapsed = Date().timeIntervalSince(startTime)
            self.lastGenerationDuration = elapsed
            self.lastTokenCount = counter.count
            self.lastTokensPerSecond = elapsed > 0 ? Double(counter.count) / elapsed : 0
        }
    }

    public func generateStructured<T: Decodable & Sendable>(
        prompt: String,
        schemaJSON: String?,
        temperature: Double,
        seed: UInt64?,
        as type: T.Type
    ) async throws -> T {
        var fullResponse = ""
        let stream = try await generate(
            prompt: prompt,
            schemaJSON: schemaJSON,
            temperature: temperature,
            seed: seed
        )
        for try await token in stream {
            fullResponse += token
        }

        let jsonString = extractJSON(from: fullResponse)
        guard let data = jsonString.data(using: .utf8) else {
            throw LlamaCppBackendError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw LlamaCppBackendError.decodingFailed(error, rawResponse: fullResponse)
        }
    }

    public func cancel() {
        isCancelled = true
    }

    public func unload() {
        isCancelled = true
        runner = nil
        isLoaded = false
    }

    // MARK: - Diagnostics

    public var diagnostics: LlamaDiagnostics {
        LlamaDiagnostics(
            isLoaded: isLoaded,
            modelPath: currentModelPath,
            loadDuration: loadDuration,
            lastGenerationDuration: lastGenerationDuration,
            lastTokenCount: lastTokenCount,
            lastTokensPerSecond: lastTokensPerSecond
        )
    }

    // MARK: - Helpers

    private func extractJSON(from text: String) -> String {
        if let jsonStart = text.range(of: "```json"),
           let jsonEnd = text.range(of: "```", range: jsonStart.upperBound..<text.endIndex) {
            return String(text[jsonStart.upperBound..<jsonEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let codeStart = text.range(of: "```"),
           let codeEnd = text.range(of: "```", range: codeStart.upperBound..<text.endIndex) {
            return String(text[codeStart.upperBound..<codeEnd.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let braceStart = text.firstIndex(of: "{"),
           let braceEnd = text.lastIndex(of: "}") {
            return String(text[braceStart...braceEnd])
        }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - InferenceRunner (thread-safe llama.cpp access)

/// Serializes inference requests so LlamaClient (not thread-safe) is never called
/// from more than one task at a time. Uses task-chaining.
private actor InferenceRunner {
    private var client: LlamaClient?
    private let modelURL: URL
    private var tailTask: Task<Void, Error>?

    init(modelURL: URL) {
        self.modelURL = modelURL
    }

    func infer(prompt: String, onToken: @Sendable @escaping (String) -> Void) async throws {
        let previous = tailTask
        let task: Task<Void, Error> = Task { [weak self] in
            _ = await previous?.result
            guard !Task.isCancelled, let self else { return }
            try await self.runInference(prompt: prompt, onToken: onToken)
        }
        tailTask = task
        try await task.value
    }

    private func runInference(prompt: String, onToken: @Sendable @escaping (String) -> Void) async throws {
        let client = try loadedClient()
        let input = LLMInput.chat([.user(prompt)])
        let generator = try client.textStream(from: input)
        for try await token in generator {
            if Task.isCancelled { break }
            onToken(token)
        }
    }

    private func loadedClient() throws -> LlamaClient {
        if let existing = client {
            return existing
        }
        do {
            let newClient = try LlamaClient(
                url: modelURL,
                mmprojURL: nil,
                parameter: .init(
                    context: 4096,
                    temperature: 0.7,
                    topK: 20,
                    topP: 0.8,
                    penaltyRepeat: 1.5
                ),
                messageProcessor: nil
            )
            client = newClient
            return newClient
        } catch {
            throw LlamaCppBackendError.contextCreationFailed(error.localizedDescription)
        }
    }
}

// MARK: - AsyncThrowingStream helper

extension AsyncThrowingStream where Failure == Error {
    static func taskBacked(
        _ body: @escaping (Continuation) async throws -> Void
    ) -> AsyncThrowingStream<Element, Failure> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    try await body(continuation)
                    continuation.finish()
                } catch let error as CancellationError {
                    continuation.finish(throwing: error)
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}

// MARK: - Types

private final class TokenCounter: @unchecked Sendable {
    var count: Int = 0
}

public struct LlamaDiagnostics: Sendable {
    public let isLoaded: Bool
    public let modelPath: String?
    public let loadDuration: TimeInterval
    public let lastGenerationDuration: TimeInterval
    public let lastTokenCount: Int
    public let lastTokensPerSecond: Double
}

public enum LlamaCppBackendError: Error, LocalizedError {
    case modelNotLoaded
    case invalidResponse
    case ggufFileNotFound
    case contextCreationFailed(String)
    case decodingFailed(Error, rawResponse: String)

    public var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            "Model not loaded. Call load() first."
        case .invalidResponse:
            "Invalid response from model."
        case .ggufFileNotFound:
            "No .gguf file found in the resolved model snapshot."
        case .contextCreationFailed(let msg):
            "Failed to create llama.cpp context: \(msg)"
        case .decodingFailed(let error, let raw):
            "Failed to decode response as JSON: \(error.localizedDescription)\n\nRaw response:\n\(raw.prefix(500))"
        }
    }
}
