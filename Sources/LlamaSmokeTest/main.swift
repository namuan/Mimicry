import Foundation
import LocalLLMClient
import LocalLLMClientLlama

@main
struct LlamaSmokeTest {
    static func main() async {
        // Find the smallest GGUF in the huggingface cache
        let hubDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".cache/huggingface/hub")

        guard let enumerator = FileManager.default.enumerator(
            at: hubDir,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            print("FAIL: No hub directory at \(hubDir.path)")
            return
        }

        // Collect synchronously first
        var ggufFiles: [(URL, Int)] = []
        while let url = enumerator.nextObject() as? URL {
            guard url.pathExtension == "gguf", !url.lastPathComponent.hasPrefix("mmproj") else { continue }
            let resolved = url.resolvingSymlinksInPath()
            var st = stat()
            guard stat(resolved.path, &st) == 0, st.st_size > 0 else { continue }
            ggufFiles.append((url, Int(st.st_size)))
        }

        ggufFiles.sort { $0.1 < $1.1 }
        guard let (modelURL, fileSize) = ggufFiles.first else {
            print("FAIL: No GGUF files found in \(hubDir.path)")
            return
        }

        print("Model: \(modelURL.lastPathComponent) (\(fileSize / 1024 / 1024) MB)")
        print("Path: \(modelURL.path)")
        print("Loading...")

        do {
            let loadStart = Date()
            let client = try LlamaClient(
                url: modelURL,
                mmprojURL: nil,
                parameter: .init(
                    context: 2048,
                    temperature: 0.7,
                    topK: 20,
                    topP: 0.8,
                    penaltyRepeat: 1.5
                ),
                messageProcessor: nil
            )
            let loadTime = Date().timeIntervalSince(loadStart)
            print("Loaded in \(String(format: "%.2f", loadTime))s")

            let input = LLMInput.chat([.user("Say hello in exactly one sentence.")])
            let stream = try client.textStream(from: input)

            print("Generating...")
            let genStart = Date()
            var output = ""
            var tokens = 0
            for try await token in stream {
                output += token
                tokens += 1
            }
            let genTime = Date().timeIntervalSince(genStart)

            print("Output: \(output.trimmingCharacters(in: .whitespacesAndNewlines))")
            print("Tokens: \(tokens) in \(String(format: "%.2f", genTime))s (\(String(format: "%.1f", Double(tokens) / genTime)) tok/s)")
            print("")
            print("========================================")
            print("PASS: llama.cpp backend generated output")
            print("========================================")
        } catch {
            print("")
            print("========================================")
            print("FAIL: \(error)")
            print("========================================")
            exit(1)
        }
    }
}
