import Foundation
import MLXBackend

@main
struct MLXSmokeTest {
    static func main() {
        let hubDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache/huggingface/hub")

        guard let modelDir = findQwen3TTSModel(in: hubDir) else {
            print("No Qwen3 TTS model found.")
            return
        }

        let service = Qwen3TTSService()
        do {
            try service.load(from: modelDir.path)
        } catch {
            print("Failed to load model: \(error)")
            return
        }
        print("Model: \(service.modelType), Speakers: \(service.speakers.joined(separator: ", "))")

        let speaker = service.speakers.first ?? "aiden"
        let text = "The corridor was completely dark. Elena pressed her back against the cold wall."
        print("Generating \"\(text)\" with speaker: \(speaker)")

        let genStart = Date()
        do {
            let (data, rate, duration) = try service.generate(text: text, speaker: speaker, language: "english")
            let genTime = Date().timeIntervalSince(genStart)
            let rtf = duration > 0 ? genTime / duration : 0

            let outURL = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop/qwen3_fixed.wav")
            try data.write(to: outURL)

            print("Duration: \(String(format: "%.2f", duration))s, \(rate)Hz, \(data.count) bytes")
            print("Time: \(String(format: "%.1f", genTime))s (RTF: \(String(format: "%.2f", rtf))x)")
            print("Saved: \(outURL.path)")
            print("\n=== TEST PASSED ✅ ===")
        } catch {
            print("FAILED: \(error)")
        }
    }

    private static func findQwen3TTSModel(in hubDir: URL) -> URL? {
        guard let dirs = try? FileManager.default.contentsOfDirectory(atPath: hubDir.path) else { return nil }
        for dirName in dirs.sorted() {
            guard dirName.hasPrefix("models--"),
                  dirName.lowercased().contains("qwen3"),
                  dirName.lowercased().contains("tts"),
                  dirName.lowercased().contains("custom") else { continue }
            let snapshotsDir = URL(fileURLWithPath: dirName, relativeTo: hubDir)
                .appendingPathComponent("snapshots")
            guard let snapshots = try? FileManager.default.contentsOfDirectory(atPath: snapshotsDir.path),
                  let hash = snapshots.first,
                  let files = try? FileManager.default.contentsOfDirectory(atPath: snapshotsDir.appendingPathComponent(hash).path),
                  files.contains(where: { $0.hasSuffix(".safetensors") }),
                  files.contains(where: { $0 == "vocab.json" })
            else { continue }
            return snapshotsDir.appendingPathComponent(hash)
        }
        return nil
    }
}
