import Foundation
import StudioDomain
@preconcurrency import StudioServices

/// Real speech generation using macOS `say` command.
/// Uses system TTS voices for testing the audio pipeline.
public actor SaySpeechService: @preconcurrency SpeechGenerating {
    private var isCancelled = false

    public init() {}

    public func generateSpeech(
        text: String,
        voiceProfile: VoiceProfile,
        performanceDirection: String?,
        speakingRate: Double?,
        seed: UInt64?
    ) async throws -> GeneratedSpeech {
        isCancelled = false

        let tempDir = FileManager.default.temporaryDirectory
        let aiffURL = tempDir.appendingPathComponent("say_output_\(UUID().uuidString).aiff")

        // Build say command
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        var args = ["-o", aiffURL.path]

        // Voice selection
        if let accent = voiceProfile.accent?.lowercased() {
            if accent.contains("british") {
                args += ["-v", "Daniel"]
            } else if accent.contains("australian") {
                args += ["-v", "Karen"]
            } else if accent.contains("scottish") {
                args += ["-v", "Fiona"]
            } else if accent.contains("irish") {
                args += ["-v", "Moira"]
            } else if accent.contains("indian") {
                args += ["-v", "Veena"]
            } else {
                args += ["-v", "Samantha"]  // Default American English
            }
        } else {
            args += ["-v", "Samantha"]
        }

        // Speaking rate
        if let rate = speakingRate {
            let wordsPerMinute = Int(rate * 175) // Base ~175 wpm
            args += ["-r", "\(wordsPerMinute)"]
        }

        args.append(text)

        task.arguments = args

        let stderrPipe = Pipe()
        task.standardError = stderrPipe
        task.standardOutput = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()

            if isCancelled {
                try? FileManager.default.removeItem(at: aiffURL)
                throw CancellationError()
            }

            guard task.terminationStatus == 0 else {
                let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                throw SaySpeechError.sayCommandFailed(status: task.terminationStatus, stderr: stderr)
            }

            // Read the AIFF file
            guard let aiffData = try? Data(contentsOf: aiffURL), !aiffData.isEmpty else {
                throw SaySpeechError.noOutputGenerated
            }

            let wavData = aiffData  // AVAudioPlayer handles AIFF natively
            try? FileManager.default.removeItem(at: aiffURL)

            let duration = estimateAIFFDuration(wavData) ?? 3.0

            return GeneratedSpeech(
                audioData: wavData,
                sampleRate: 22050,
                channelCount: 1,
                duration: duration,
                metadata: [
                    "generator": "macOS-say",
                    "voice": voiceProfile.name,
                    "text": text,
                ]
            )
        } catch {
            try? FileManager.default.removeItem(at: aiffURL)
            throw error
        }
    }

    /// Convenience: generate speech with a voice name and rate directly.
    /// Uses the macOS `say` command with the given system voice.
    public func generateSpeech(
        text: String,
        voiceName: String = "Samantha",
        rate: Double = 1.0
    ) async throws -> GeneratedSpeech {
        isCancelled = false

        let tempDir = FileManager.default.temporaryDirectory
        let aiffURL = tempDir.appendingPathComponent("say_output_\(UUID().uuidString).aiff")

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/say")
        let wordsPerMinute = Int(max(60, min(720, rate * 175)))
        task.arguments = ["-v", voiceName, "-r", "\(wordsPerMinute)", "-o", aiffURL.path, text]

        let stderrPipe = Pipe()
        task.standardError = stderrPipe
        task.standardOutput = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()

            if isCancelled {
                try? FileManager.default.removeItem(at: aiffURL)
                throw CancellationError()
            }

            guard task.terminationStatus == 0 else {
                let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
                throw SaySpeechError.sayCommandFailed(status: task.terminationStatus, stderr: stderr)
            }

            guard let aiffData = try? Data(contentsOf: aiffURL), !aiffData.isEmpty else {
                throw SaySpeechError.noOutputGenerated
            }

            // AVAudioPlayer handles AIFF natively — no WAV conversion needed
            let audioData = aiffData

            // Clean up temp file
            try? FileManager.default.removeItem(at: aiffURL)

            // Estimate duration from AIFF sample rate (typically 22050 for say)
            let duration = estimateAIFFDuration(aiffData) ?? 3.0

            return GeneratedSpeech(
                audioData: audioData,
                sampleRate: 22050,
                channelCount: 1,
                duration: duration,
                metadata: [
                    "generator": "macOS-say",
                    "voice": voiceName,
                    "rate": "\(rate)x",
                ]
            )
        } catch {
            try? FileManager.default.removeItem(at: aiffURL)
            throw error
        }
    }

    public func cancel() {
        isCancelled = true
    }

    private func estimateAIFFDuration(_ data: Data) -> Double? {
        guard data.count > 12 else { return nil }
        let sampleRate = 22050.0
        var ssndSize: Int?

        var offset = 12
        while offset + 8 <= data.count {
            let chunkID = String(data: data.subdata(in: offset..<offset+4), encoding: .ascii) ?? ""
            let chunkSize = Int(data.withUnsafeBytes { ptr in
                ptr.loadUnaligned(fromByteOffset: offset + 4, as: Int32.self).bigEndian
            })
            if chunkID == "SSND" {
                ssndSize = chunkSize - 8
                break
            }
            offset += 8 + chunkSize + (chunkSize % 2)
            if offset >= data.count { break }
        }

        guard let size = ssndSize, size > 0 else { return nil }
        return Double(size / 2) / sampleRate
    }
}

public enum SaySpeechError: Error, LocalizedError {
    case sayCommandFailed(status: Int32, stderr: String)
    case noOutputGenerated

    public var errorDescription: String? {
        switch self {
        case .sayCommandFailed(let status, let stderr):
            "say command exited with status \(status): \(stderr)"
        case .noOutputGenerated:
            "say command produced no audio output"
        }
    }
}
