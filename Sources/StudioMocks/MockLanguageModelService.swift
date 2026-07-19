import Foundation
import StudioServices

/// Mock LLM service that returns predetermined responses for audiobook analysis tasks.
public final class MockLanguageModelService: LanguageModelServing, @unchecked Sendable {
    private nonisolated(unsafe) var isCancelled = false

    public init() {}

    public func generate(
        prompt: String,
        schemaJSON: String?,
        temperature: Double,
        seed: UInt64?
    ) async throws -> AsyncThrowingStream<String, Error> {
        isCancelled = false

        return AsyncThrowingStream { continuation in
            Task {
                defer { continuation.finish() }

                let words: [String]
                if prompt.contains("scene") && prompt.contains("character") {
                    words = MockResponses.sceneCharacterAnalysis.components(separatedBy: .whitespaces)
                } else if prompt.contains("dialogue") {
                    words = MockResponses.dialogueAttribution.components(separatedBy: .whitespaces)
                } else {
                    words = MockResponses.generalAnalysis.components(separatedBy: .whitespaces)
                }

                for word in words {
                    let cancelled = isCancelled
                    if cancelled {
                        continuation.finish(throwing: CancellationError())
                        return
                    }
                    continuation.yield(word + " ")
                    try? await Task.sleep(for: .milliseconds(20))
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
        // Simulate processing time
        try await Task.sleep(for: .seconds(1.0))

        let jsonString: String
        if prompt.contains("scene") && prompt.contains("character") {
            jsonString = MockResponses.sceneCharacterJSON
        } else if prompt.contains("dialogue") {
            jsonString = MockResponses.dialogueJSON
        } else {
            jsonString = MockResponses.generalJSON
        }

        guard let data = jsonString.data(using: .utf8) else {
            throw MockModelError.invalidJSON
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw MockModelError.decodingFailed(error)
        }
    }

    public func cancel() {
        isCancelled = true
    }

    public func unload() {
        // No-op for mock
    }
}

public enum MockModelError: Error {
    case invalidJSON
    case decodingFailed(Error)
}

private enum MockResponses {
    static let sceneCharacterAnalysis = """
    Analysis complete. Found 10 scenes across 3 chapters. Identified 7 distinct characters including narrator. \
    One potential duplicate detected between Elena Vasquez and Dr. Helena Vance (82 percent confidence). \
    Three dialogue blocks require speaker attribution.
    """

    static let dialogueAttribution = """
    Dialogue analysis complete. Attributed 15 dialogue blocks to known characters. \
    2 blocks have ambiguous speakers requiring manual review. \
    1 block has below-threshold speaker confidence.
    """

    static let generalAnalysis = """
    Processing complete. The text contains complex character interactions and layered narrative structure. \
    Multiple viewpoint shifts detected across chapters.
    """

    static let sceneCharacterJSON = """
    {"scenes": [{"id": "scene-1", "title": "The Courier", "confidence": 0.95}], "characters": [{"name": "Elena Vasquez", "aliases": ["Elena", "Ms. Vasquez"]}]}
    """

    static let dialogueJSON = """
    {"blocks": [{"speaker": "Elena", "text": "Who's there?", "confidence": 0.95}]}
    """

    static let generalJSON = """
    {"summary": "Analysis complete", "confidence": 0.88}
    """
}
