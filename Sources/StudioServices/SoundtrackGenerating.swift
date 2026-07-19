import Foundation
import StudioDomain

/// Scene audio / soundtrack generation protocol.
public protocol SoundtrackGenerating: Sendable {
    func generateSceneAudio(
        settings: SoundDesignSettings,
        requestedDuration: TimeInterval
    ) async throws -> GeneratedSceneAudio

    func cancel()
}

/// Result of scene audio generation.
public struct GeneratedSceneAudio: Sendable {
    public let musicData: Data?
    public let ambienceData: Data?
    public let musicDuration: TimeInterval?
    public let ambienceDuration: TimeInterval?
    public let musicIsLoopable: Bool
    public let ambienceIsLoopable: Bool
    public let metadata: [String: String]

    public init(
        musicData: Data? = nil,
        ambienceData: Data? = nil,
        musicDuration: TimeInterval? = nil,
        ambienceDuration: TimeInterval? = nil,
        musicIsLoopable: Bool = false,
        ambienceIsLoopable: Bool = false,
        metadata: [String: String] = [:]
    ) {
        self.musicData = musicData
        self.ambienceData = ambienceData
        self.musicDuration = musicDuration
        self.ambienceDuration = ambienceDuration
        self.musicIsLoopable = musicIsLoopable
        self.ambienceIsLoopable = ambienceIsLoopable
        self.metadata = metadata
    }
}
