import Foundation

/// Generic language model serving protocol used for LLM-based tasks.
public protocol LanguageModelServing: Sendable {
    func generate(
        prompt: String,
        schemaJSON: String?,
        temperature: Double,
        seed: UInt64?
    ) async throws -> AsyncThrowingStream<String, Error>

    func generateStructured<T: Decodable & Sendable>(
        prompt: String,
        schemaJSON: String?,
        temperature: Double,
        seed: UInt64?,
        as type: T.Type
    ) async throws -> T

    func cancel()
    func unload()
}
