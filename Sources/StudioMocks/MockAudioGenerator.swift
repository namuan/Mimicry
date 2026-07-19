import Foundation

/// Generates synthetic audio data for mock voice and scene previews.
public enum MockAudioGenerator {
    /// Generate a simple sine wave tone as a WAV file.
    /// - Parameters:
    ///   - frequency: Tone frequency in Hz
    ///   - duration: Duration in seconds
    ///   - sampleRate: Sample rate in Hz
    /// - Returns: WAV file data (44-byte header + PCM samples)
    public static func generateTone(
        frequency: Double = 440,
        duration: TimeInterval = 3.0,
        sampleRate: Int = 24000
    ) -> Data {
        let numSamples = Int(Double(sampleRate) * duration)
        let dataSize = numSamples * 2 // 16-bit mono
        let fileSize = 44 + dataSize

        var data = Data(capacity: fileSize)

        // RIFF header
        data.append("RIFF".data(using: .ascii)!)
        data.append(fileSizeVar(fileSize - 8))
        data.append("WAVE".data(using: .ascii)!)

        // fmt subchunk
        data.append("fmt ".data(using: .ascii)!)
        var fmtSize: Int32 = 16
        data.append(Data(bytes: &fmtSize, count: 4))
        var audioFormat: Int16 = 1 // PCM
        data.append(Data(bytes: &audioFormat, count: 2))
        var numChannels: Int16 = 1
        data.append(Data(bytes: &numChannels, count: 2))
        var sr: Int32 = Int32(sampleRate)
        data.append(Data(bytes: &sr, count: 4))
        var byteRate: Int32 = Int32(sampleRate * 2) // sampleRate * numChannels * bytesPerSample
        data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign: Int16 = 2
        data.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample: Int16 = 16
        data.append(Data(bytes: &bitsPerSample, count: 2))

        // data subchunk
        data.append("data".data(using: .ascii)!)
        data.append(fileSizeVar(dataSize))

        // Generate sine wave
        for i in 0..<numSamples {
            let t = Double(i) / Double(sampleRate)
            let amplitude = 0.3 * (1.0 - Double(i) / Double(numSamples)) // fade out
            let sample = Int16(sin(2.0 * .pi * frequency * t) * amplitude * Double(Int16.max))
            var s = sample
            data.append(Data(bytes: &s, count: 2))
        }

        return data
    }

    /// Generate a noise-based ambient sound as WAV data.
    public static func generateAmbient(
        duration: TimeInterval = 5.0,
        sampleRate: Int = 24000
    ) -> Data {
        let numSamples = Int(Double(sampleRate) * duration)
        let dataSize = numSamples * 2
        let fileSize = 44 + dataSize
        var data = Data(capacity: fileSize)

        data.append("RIFF".data(using: .ascii)!)
        data.append(fileSizeVar(fileSize - 8))
        data.append("WAVE".data(using: .ascii)!)

        data.append("fmt ".data(using: .ascii)!)
        var fmtSize: Int32 = 16; data.append(Data(bytes: &fmtSize, count: 4))
        var audioFormat: Int16 = 1; data.append(Data(bytes: &audioFormat, count: 2))
        var numChannels: Int16 = 1; data.append(Data(bytes: &numChannels, count: 2))
        var sr: Int32 = Int32(sampleRate); data.append(Data(bytes: &sr, count: 4))
        var byteRate: Int32 = Int32(sampleRate * 2); data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign: Int16 = 2; data.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample: Int16 = 16; data.append(Data(bytes: &bitsPerSample, count: 2))

        data.append("data".data(using: .ascii)!)
        data.append(fileSizeVar(dataSize))

        for i in 0..<numSamples {
            let envelope = min(1.0, Double(i) / Double(sampleRate)) * (1.0 - Double(i) / Double(numSamples))
            let noise = Double.random(in: -1...1) * 0.15 * envelope
            var sample = Int16(noise * Double(Int16.max))
            data.append(Data(bytes: &sample, count: 2))
        }

        return data
    }

    private static func fileSizeVar(_ size: Int) -> Data {
        var s = Int32(size)
        return Data(bytes: &s, count: 4)
    }
}
