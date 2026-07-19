import Foundation
import StudioDomain
import StudioServices

/// Mock audio mixer that concatenates audio data with simulated mixing.
public final class MockAudioMixer: AudioMixing, @unchecked Sendable {
    public init() {}

    public func mixScene(
        speechBlocks: [(ScriptBlock, Data)],
        soundtrack: GeneratedSceneAudio?,
        settings: SoundDesignSettings?
    ) async throws -> Data {
        try await Task.sleep(for: .seconds(1.0))

        // Simple concatenation of all audio data with a small gap
        var mixed = Data()
        for (_, audio) in speechBlocks {
            mixed.append(audio)
            // Add 0.5s silence between blocks
            let silenceSamples = 24000 / 2 // 0.5s at 24kHz, 16-bit
            let silence = Data(count: silenceSamples * 2)
            mixed.append(silence)
        }

        // Append soundtrack if present
        if let music = soundtrack?.musicData {
            mixed.append(music)
        }
        if let ambience = soundtrack?.ambienceData {
            mixed.append(ambience)
        }

        return mixed
    }

    public func mixChapter(sceneAudio: [Data]) async throws -> Data {
        try await Task.sleep(for: .seconds(1.5))

        var mixed = Data()
        for audio in sceneAudio {
            mixed.append(audio)
        }
        return mixed
    }
}
