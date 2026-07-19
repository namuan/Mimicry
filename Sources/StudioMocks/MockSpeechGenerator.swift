import Foundation
import StudioDomain
import StudioServices

/// Mock speech generator that produces tone-based audio simulating TTS output.
public final class MockSpeechGenerator: SpeechGenerating, @unchecked Sendable {
    private nonisolated(unsafe) var isCancelled = false

    public init() {}

    public func generateSpeech(
        text: String,
        voiceProfile: VoiceProfile,
        performanceDirection: String?,
        speakingRate: Double?,
        seed: UInt64?
    ) async throws -> GeneratedSpeech {
        isCancelled = false

        let wordCount = text.split(separator: " ").count
        let estimatedDuration = Double(wordCount) / 3.0 // ~3 words per second
        let simulatedDuration = min(estimatedDuration, 3.0) // Cap simulation time

        // Simulate generation time
        let steps = max(1, Int(simulatedDuration / 0.3))
        for _ in 0..<steps {
            let cancelled = isCancelled
            if cancelled { throw CancellationError() }
            try await Task.sleep(for: .milliseconds(300))
        }

        // Generate tone audio based on voice characteristics
        let baseFreq: Double
        if let tone = voiceProfile.tone {
            if tone.contains("deep") || tone.contains("baritone") || tone.contains("commanding") {
                baseFreq = 150
            } else if tone.contains("alto") || tone.contains("warm") {
                baseFreq = 250
            } else if tone.contains("tenor") || tone.contains("fast") {
                baseFreq = 350
            } else {
                baseFreq = 280
            }
        } else {
            baseFreq = 280
        }

        // Vary frequency slightly to simulate speech intonation
        var audioData = Data()
        let sampleRate = 24000
        let numSamples = Int(Double(sampleRate) * estimatedDuration)

        // Build WAV header
        let dataSize = numSamples * 2
        audioData.append(wavHeader(dataSize: dataSize, sampleRate: sampleRate))

        for i in 0..<numSamples {
            let t = Double(i) / Double(sampleRate)
            // Simulate pitch variation
            let freq = baseFreq + sin(2.0 * .pi * 3.0 * t) * 30.0
            let progress = Double(i) / Double(sampleRate)
            let attack = min(1.0, progress / 0.05)
            let release = 1.0 - Double(i) / Double(numSamples)
            let envelope = attack * release
            let amplitude = 0.4 * envelope
            var sample = Int16(sin(2.0 * .pi * freq * t) * amplitude * Double(Int16.max))
            audioData.append(Data(bytes: &sample, count: 2))
        }

        return GeneratedSpeech(
            audioData: audioData,
            sampleRate: sampleRate,
            channelCount: 1,
            duration: estimatedDuration,
            metadata: [
                "generator": "mock-tts-v1",
                "model": voiceProfile.generationMetadata["model"] ?? "unknown",
                "text": text,
                "voice": voiceProfile.name,
            ]
        )
    }

    public func cancel() {
        isCancelled = true
    }

    private func wavHeader(dataSize: Int, sampleRate: Int) -> Data {
        var data = Data()
        data.append("RIFF".data(using: .ascii)!)
        var fileSize = Int32(36 + dataSize)
        data.append(Data(bytes: &fileSize, count: 4))
        data.append("WAVE".data(using: .ascii)!)
        data.append("fmt ".data(using: .ascii)!)
        var fmtSize: Int32 = 16
        data.append(Data(bytes: &fmtSize, count: 4))
        var audioFormat: Int16 = 1
        data.append(Data(bytes: &audioFormat, count: 2))
        var numChannels: Int16 = 1
        data.append(Data(bytes: &numChannels, count: 2))
        var sr: Int32 = Int32(sampleRate)
        data.append(Data(bytes: &sr, count: 4))
        var byteRate: Int32 = Int32(sampleRate * 2)
        data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign: Int16 = 2
        data.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample: Int16 = 16
        data.append(Data(bytes: &bitsPerSample, count: 2))
        data.append("data".data(using: .ascii)!)
        var ds = Int32(dataSize)
        data.append(Data(bytes: &ds, count: 4))
        return data
    }
}
