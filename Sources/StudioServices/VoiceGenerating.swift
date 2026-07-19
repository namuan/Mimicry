import Foundation
import StudioDomain

/// Voice profile generation protocol.
public protocol VoiceProfileGenerating: Sendable {
    func generateVoice(
        description: String,
        accent: String?,
        ageRange: String?,
        tone: String?,
        sampleText: String,
        seed: UInt64?
    ) async throws -> VoiceProfile
}

/// Character voice assignment protocol.
public protocol VoiceGenerating: Sendable {
    func suggestVoices(for character: Character) async throws -> [VoiceProfile]
    func previewVoice(_ profile: VoiceProfile, text: String) async throws -> Data
}
