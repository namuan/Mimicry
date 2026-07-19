import Foundation
import ModelRegistry
import HuggingFaceCache
@preconcurrency import StudioServices
import MLX
import MLXLLM
import MLXLMCommon
import Tokenizers

/// A `TokenizerLoader` that loads a HuggingFace tokenizer from a local directory.
private struct HuggingFaceTokenizerLoader: TokenizerLoader {
    func load(from directory: URL) async throws -> any MLXLMCommon.Tokenizer {
        struct Bridge: MLXLMCommon.Tokenizer {
            let upstream: Tokenizers.Tokenizer

            func encode(text: String, addSpecialTokens: Bool) -> [Int] {
                upstream.encode(text: text, addSpecialTokens: addSpecialTokens)
            }

            func decode(tokenIds: [Int], skipSpecialTokens: Bool) -> String {
                upstream.decode(tokens: tokenIds, skipSpecialTokens: skipSpecialTokens)
            }

            func convertTokenToId(_ token: String) -> Int? {
                upstream.convertTokenToId(token)
            }

            func convertIdToToken(_ id: Int) -> String? {
                upstream.convertIdToToken(id)
            }

            var bosToken: String? { upstream.bosToken }
            var eosToken: String? { upstream.eosToken }
            var unknownToken: String? { upstream.unknownToken }

            func applyChatTemplate(
                messages: [[String: any Sendable]],
                tools: [[String: any Sendable]]?,
                additionalContext: [String: any Sendable]?
            ) throws -> [Int] {
                do {
                    return try upstream.applyChatTemplate(
                        messages: messages,
                        tools: tools,
                        additionalContext: additionalContext
                    )
                } catch {
                    if let tokenizerError = error as? Tokenizers.TokenizerError {
                        switch tokenizerError {
                        case .missingChatTemplate:
                            throw MLXLMCommon.TokenizerError.missingChatTemplate
                        default:
                            throw error
                        }
                    }
                    throw error
                }
            }
        }

        let upstream = try await AutoTokenizer.from(modelFolder: directory)
        return Bridge(upstream: upstream)
    }
}

/// Real language model service backed by MLX Swift and MLX Swift LM.
/// Loads models directly from the Hugging Face cache and generates locally.
public actor MLXLanguageModelService: @preconcurrency LanguageModelServing {
    private let resolver: ModelResolver
    private var container: ModelContainer?
    private var isLoaded = false
    private var isCancelled = false
    private var currentSpec: HuggingFaceModelSpecification?

    // Diagnostics
    private var loadStartTime: Date?
    private var loadDuration: TimeInterval = 0
    private var tokenCount: Int = 0
    private var generationStartTime: Date?
    public private(set) var lastTokensPerSecond: Double = 0
    public private(set) var lastGenerationDuration: TimeInterval = 0
    public private(set) var lastTokenCount: Int = 0

    public init(resolver: ModelResolver) {
        self.resolver = resolver
    }

    /// Load an MLX model from the Hugging Face cache.
    public func load(_ specification: HuggingFaceModelSpecification) async throws {
        loadStartTime = Date()

        let resolved = try await resolver.resolve(
            specification,
            policy: .online
        )

        // Pre-flight: validate that model files actually exist with content
        let missingOrEmpty = resolved.modelFiles.filter { fileURL in
            let resolved = fileURL.resolvingSymlinksInPath()
            guard FileManager.default.fileExists(atPath: resolved.path) else { return true }
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: resolved.path),
                  let size = attrs[.size] as? Int64, size > 0 else { return true }
            return false
        }

        if !missingOrEmpty.isEmpty {
            throw MLXBackendError.modelIncomplete(
                files: missingOrEmpty.map { $0.lastPathComponent },
                message: "Model snapshot exists but \(missingOrEmpty.count) file(s) are missing or empty. The model weights may not have been downloaded — only metadata symlinks exist. Use the Models tab to download the model first."
            )
        }

        // Load model directly from the snapshot directory using the
        // new ModelFactory API that accepts a directory URL plus a
        // tokenizer loader.
        let container = try await loadModelContainer(
            from: resolved.snapshotDirectory,
            using: HuggingFaceTokenizerLoader()
        )

        self.container = container
        self.currentSpec = specification
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
        guard let container, isLoaded else {
            throw MLXBackendError.modelNotLoaded
        }

        isCancelled = false
        generationStartTime = Date()
        tokenCount = 0

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

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let input = try await container.prepare(
                        input: UserInput(prompt: finalPrompt)
                    )

                    var parameters = GenerateParameters()
                    parameters.temperature = Float(temperature)
                    parameters.maxTokens = 2048
                    if let seed = seed {
                        parameters.seed = seed
                    }

                    let stream = try await container.generate(
                        input: input,
                        parameters: parameters
                    )

                    for await generation in stream {
                        if self.isCancelled {
                            continuation.finish(throwing: CancellationError())
                            return
                        }
                        switch generation {
                        case .chunk(let text):
                            tokenCount += 1
                            continuation.yield(text)
                        case .info(let info):
                            // Generation metadata, could log
                            _ = info
                        case .toolCall:
                            break
                        }
                    }

                    if let start = self.generationStartTime {
                        self.lastGenerationDuration = Date().timeIntervalSince(start)
                        self.lastTokenCount = self.tokenCount
                        self.lastTokensPerSecond = self.lastGenerationDuration > 0
                            ? Double(self.tokenCount) / self.lastGenerationDuration
                            : 0
                    }

                    continuation.finish()
                } catch let error as CancellationError {
                    continuation.finish(throwing: error)
                } catch {
                    continuation.finish(throwing: MLXBackendError.generationFailed(error))
                }
            }
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

        // Extract JSON from response (handle markdown code blocks)
        let jsonString = extractJSON(from: fullResponse)
        guard let data = jsonString.data(using: .utf8) else {
            throw MLXBackendError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw MLXBackendError.decodingFailed(error, rawResponse: fullResponse)
        }
    }

    public func cancel() {
        isCancelled = true
    }

    public func unload() {
        isCancelled = true
        container = nil
        isLoaded = false
    }

    // MARK: - Diagnostics

    public var diagnostics: MLXDiagnostics {
        MLXDiagnostics(
            isLoaded: isLoaded,
            modelName: currentSpec?.displayName,
            loadDuration: loadDuration,
            lastGenerationDuration: lastGenerationDuration,
            lastTokenCount: lastTokenCount,
            lastTokensPerSecond: lastTokensPerSecond
        )
    }

    // MARK: - Helpers

    /// Extract JSON from a response that may contain markdown code blocks.
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

/// Diagnostics collected during MLX model operation.
public struct MLXDiagnostics: Sendable {
    public let isLoaded: Bool
    public let modelName: String?
    public let loadDuration: TimeInterval
    public let lastGenerationDuration: TimeInterval
    public let lastTokenCount: Int
    public let lastTokensPerSecond: Double
}

public enum MLXBackendError: Error, LocalizedError {
    case modelNotLoaded
    case invalidResponse
    case architectureNotSupported(String)
    case memoryExceeded(available: Int64, required: Int64)
    case generationFailed(Error)
    case decodingFailed(Error, rawResponse: String)
    case modelIncomplete(files: [String], message: String)

    public var errorDescription: String? {
        switch self {
        case .modelNotLoaded:
            "Model not loaded. Call load() first."
        case .invalidResponse:
            "Invalid response from model."
        case .architectureNotSupported(let name):
            "Model architecture not supported by current MLX Swift LM: \(name)"
        case .memoryExceeded(let available, let required):
            "Insufficient memory: \(HuggingFaceCacheConfiguration.formatBytes(required)) required, \(HuggingFaceCacheConfiguration.formatBytes(available)) available"
        case .generationFailed(let error):
            "Generation failed: \(error.localizedDescription)"
        case .decodingFailed(let error, let raw):
            "Failed to decode response as JSON: \(error.localizedDescription)\n\nRaw response:\n\(raw.prefix(500))"
        case .modelIncomplete(let files, let message):
            "Model incomplete — \(files.count) file(s) missing/empty: \(files.prefix(5).joined(separator: ", ")). \(message)"
        }
    }
}
