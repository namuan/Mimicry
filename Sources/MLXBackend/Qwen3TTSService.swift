import Foundation
import MLX

/// Wraps the vendored hamptus/mlx-swift-qwen3-tts pipeline.
/// Reads vocab.json + merges.txt directly — no tokenizer.json needed.
public class Qwen3TTSService: @unchecked Sendable {
    private var pipeline: Qwen3TTSPipeline?
    private let lock = NSLock()

    public private(set) var isLoaded = false
    public private(set) var modelType: String = ""
    public private(set) var speakers: [String] = []

    public init() {}

    public func load(from modelPath: String) throws {
        let config = Qwen3TTSPipelineConfiguration()
        let pipeline = try Qwen3TTSPipeline(modelPath: URL(fileURLWithPath: modelPath), configuration: config)
        lock.lock()
        self.pipeline = pipeline
        self.isLoaded = true
        self.modelType = pipeline.modelType ?? "unknown"
        self.speakers = pipeline.availableSpeakers
        lock.unlock()
    }

    /// Generate speech. Returns (wavData, sampleRate, durationSeconds).
    public func generate(
        text: String,
        speaker: String? = nil,
        instruct: String? = nil,
        language: String = "english"
    ) throws -> (Data, Int, Double) {
        guard let pipeline else { throw Qwen3TTSServiceError.notLoaded }

        let samples: [Float]
        let actualSpeaker = speaker ?? speakers.first

        if pipeline.supportsCustomVoice, let spk = actualSpeaker, let inst = instruct {
            samples = pipeline.generateCustomVoice(text: text, speaker: spk, instruct: inst)
        } else if pipeline.supportsVoiceDesign, let inst = instruct {
            samples = pipeline.generateVoiceDesign(text: text, voiceDescription: inst)
        } else if let spk = actualSpeaker {
            samples = pipeline.generate(text: text, speaker: spk)
        } else {
            // Base model with no named speakers — use neutral generation
            samples = pipeline.generate(text: text, speaker: "default")
        }

        let sampleRate = 24000
        let wavData = try floatSamplesToWAV(samples, sampleRate: sampleRate)
        let duration = Double(samples.count) / Double(sampleRate)
        return (wavData, sampleRate, duration)
    }

    public func unload() {
        lock.lock()
        pipeline = nil
        isLoaded = false
        speakers = []
        lock.unlock()
    }

    // MARK: - WAV conversion

    private func floatSamplesToWAV(_ samples: [Float], sampleRate: Int) throws -> Data {
        let numChannels: Int16 = 1
        let bitsPerSample: Int16 = 16
        let byteRate = Int32(sampleRate) * Int32(numChannels) * Int32(bitsPerSample) / 8
        let blockAlign = Int16(numChannels) * bitsPerSample / 8
        let dataSize = Int32(samples.count * 2)

        var wav = Data()
        wav.append("RIFF".data(using: .ascii)!)
        var fileSize = Int32(36 + dataSize)
        wav.append(Data(bytes: &fileSize, count: 4))
        wav.append("WAVE".data(using: .ascii)!)
        wav.append("fmt ".data(using: .ascii)!)
        var fmtSize: Int32 = 16; wav.append(Data(bytes: &fmtSize, count: 4))
        var fmt: Int16 = 1; wav.append(Data(bytes: &fmt, count: 2))
        var ch = numChannels; wav.append(Data(bytes: &ch, count: 2))
        var sr = Int32(sampleRate); wav.append(Data(bytes: &sr, count: 4))
        var br = byteRate; wav.append(Data(bytes: &br, count: 4))
        var ba = blockAlign; wav.append(Data(bytes: &ba, count: 2))
        var bps = bitsPerSample; wav.append(Data(bytes: &bps, count: 2))
        wav.append("data".data(using: .ascii)!)
        var ds = dataSize; wav.append(Data(bytes: &ds, count: 4))

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            var int16 = Int16(clamped * 32767.0)
            wav.append(Data(bytes: &int16, count: 2))
        }
        return wav
    }
}

public enum Qwen3TTSServiceError: Error, LocalizedError {
    case notLoaded
    case unsupportedModelType(String)
    case needsSpeaker(String)

    public var errorDescription: String? {
        switch self {
        case .notLoaded: "Qwen3 TTS model not loaded"
        case .unsupportedModelType(let type): "Unsupported TTS model type: \(type)"
        case .needsSpeaker(let type): "Model type '\(type)' has no built-in speakers. Use a CustomVoice model (e.g. 'Qwen3-TTS CustomVoice') which supports named speakers like Aiden, Vivian, Ryan etc."
        }
    }
}
