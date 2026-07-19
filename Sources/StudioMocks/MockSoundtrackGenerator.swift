import Foundation
import StudioDomain
import StudioServices

/// Mock soundtrack generator that produces ambient and music audio.
public final class MockSoundtrackGenerator: SoundtrackGenerating, @unchecked Sendable {
    private nonisolated(unsafe) var isCancelled = false

    public init() {}

    public func generateSceneAudio(
        settings: SoundDesignSettings,
        requestedDuration: TimeInterval
    ) async throws -> GeneratedSceneAudio {
        isCancelled = false

        // Simulate generation time
        let steps = max(1, Int(min(requestedDuration / 10.0, 3.0) / 0.3))
        for _ in 0..<steps {
            let cancelled = isCancelled
            if cancelled { throw CancellationError() }
            try await Task.sleep(for: .milliseconds(300))
        }

        let musicData: Data?
        let ambienceData: Data?

        if !settings.musicPrompt.isEmpty {
            musicData = MockAudioGenerator.generateTone(
                frequency: 110,
                duration: min(requestedDuration, 10.0),
                sampleRate: 24000
            )
        } else {
            musicData = nil
        }

        if !settings.ambiencePrompt.isEmpty {
            ambienceData = MockAudioGenerator.generateAmbient(
                duration: min(requestedDuration, 10.0),
                sampleRate: 24000
            )
        } else {
            ambienceData = nil
        }

        return GeneratedSceneAudio(
            musicData: musicData,
            ambienceData: ambienceData,
            musicDuration: musicData != nil ? requestedDuration : nil,
            ambienceDuration: ambienceData != nil ? requestedDuration : nil,
            musicIsLoopable: true,
            ambienceIsLoopable: true,
            metadata: [
                "generator": "mock-soundtrack-v1",
                "music_prompt": settings.musicPrompt,
                "ambience_prompt": settings.ambiencePrompt,
            ]
        )
    }

    public func cancel() {
        isCancelled = true
    }
}
