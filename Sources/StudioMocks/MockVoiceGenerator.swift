import Foundation
import StudioDomain
import StudioServices

/// Mock voice generator returning pre-built voice profiles with tone previews.
public final class MockVoiceGenerator: VoiceProfileGenerating, VoiceGenerating, @unchecked Sendable {
    public init() {}

    public func generateVoice(
        description: String,
        accent: String?,
        ageRange: String?,
        tone: String?,
        sampleText: String,
        seed: UInt64?
    ) async throws -> VoiceProfile {
        try await Task.sleep(for: .seconds(2.0))

        return VoiceProfile(
            name: "Generated Voice",
            description: description,
            accent: accent,
            ageRange: ageRange,
            tone: tone,
            sampleText: sampleText,
            seed: seed,
            previewAudioData: MockAudioGenerator.generateTone(frequency: 330, duration: 2.0),
            generationMetadata: ["model": "mock-tts-v1", "generated": "true"]
        )
    }

    public func suggestVoices(for character: Character) async throws -> [VoiceProfile] {
        try await Task.sleep(for: .seconds(1.0))

        let project = MockSampleData.buildProject()
        // Return all voice profiles except narrator (suggestions for character)
        return project.voiceProfiles.filter { !$0.isNarratorVoice }
    }

    public func previewVoice(_ profile: VoiceProfile, text: String) async throws -> Data {
        try await Task.sleep(for: .milliseconds(800))

        let baseFreq: Double
        if let tone = profile.tone {
            if tone.contains("deep") || tone.contains("baritone") {
                baseFreq = 180
            } else if tone.contains("alto") {
                baseFreq = 280
            } else {
                baseFreq = 350
            }
        } else {
            baseFreq = 300
        }

        let duration = max(1.0, Double(text.count) / 15.0)
        return MockAudioGenerator.generateTone(frequency: baseFreq, duration: duration)
    }
}
