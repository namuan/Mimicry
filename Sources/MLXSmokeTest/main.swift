import Foundation
import MLXBackend

@main
struct MLXSmokeTest {
    static func main() {
        let hubDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache/huggingface/hub")

        // Find all Qwen3 TTS models and test them
        for dirName in (try? FileManager.default.contentsOfDirectory(atPath: hubDir.path)) ?? [] {
            guard dirName.hasPrefix("models--"),
                  dirName.lowercased().contains("qwen3"),
                  dirName.lowercased().contains("tts") else { continue }
            let snapshotsDir = URL(fileURLWithPath: dirName, relativeTo: hubDir).appendingPathComponent("snapshots")
            guard let snaps = try? FileManager.default.contentsOfDirectory(atPath: snapshotsDir.path),
                  let hash = snaps.first else { continue }
            let modelDir = snapshotsDir.appendingPathComponent(hash)
            guard let files = try? FileManager.default.contentsOfDirectory(atPath: modelDir.path),
                  files.contains(where: { $0.hasSuffix(".safetensors") }) else { continue }

            let shortName = String(dirName.dropFirst("models--".count))
                .replacingOccurrences(of: "--", with: "/")
            print("\n=== \(shortName) ===")
            
            let svc = Qwen3TTSService()
            do {
                try svc.load(from: modelDir.path)
                print("Type: \(svc.modelType), Speakers: \(svc.speakers.isEmpty ? "none (default voice)" : svc.speakers.joined(separator: ", "))")
                
                let spk = svc.speakers.first
                let text = "The corridor was completely dark."
                print("Generating: \"\(text)\" speaker: \(spk ?? "default")")
                
                let start = Date()
                let (data, _, duration) = try svc.generate(text: text, speaker: spk, language: "english")
                let elapsed = Date().timeIntervalSince(start)
                print("  \(String(format: "%.2f", duration))s, \(data.count)B, RTF: \(String(format: "%.2f", elapsed/duration))x — ✅")
            } catch {
                print("  ❌ \(error.localizedDescription)")
            }
        }
    }
}
