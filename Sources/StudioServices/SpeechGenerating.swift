import Foundation
import StudioDomain

/// Speech (TTS) generation protocol.
public protocol SpeechGenerating: Sendable {
    func generateSpeech(
        text: String,
        voiceProfile: VoiceProfile,
        performanceDirection: String?,
        speakingRate: Double?,
        seed: UInt64?
    ) async throws -> GeneratedSpeech

    func cancel()
}

/// Result of speech generation.
public struct GeneratedSpeech: Sendable {
    public let audioData: Data
    public let sampleRate: Int
    public let channelCount: Int
    public let duration: TimeInterval
    public let metadata: [String: String]

    public init(
        audioData: Data,
        sampleRate: Int = 24000,
        channelCount: Int = 1,
        duration: TimeInterval = 0,
        metadata: [String: String] = [:]
    ) {
        self.audioData = audioData
        self.sampleRate = sampleRate
        self.channelCount = channelCount
        self.duration = duration
        self.metadata = metadata
    }
}
