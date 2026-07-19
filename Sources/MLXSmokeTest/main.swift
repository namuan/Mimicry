import Foundation
import HuggingFaceCache
import MLX
import MLXLLM
import MLXLMCommon
import Tokenizers

// MARK: - Tokenizer loader (adapted from MLXLanguageModelService)

private struct HuggingFaceTokenizerLoader: TokenizerLoader {
    func load(from directory: URL) async throws -> any MLXLMCommon.Tokenizer {
        struct Bridge: MLXLMCommon.Tokenizer {
            let upstream: Tokenizers.Tokenizer

            func encode(text: String, addSpecialTokens: Bool) -> [Int] {
                upstream.encode(text: text, addSpecialTokens: addSpecialTokens)
            }

            func decode(tokenIds: [Int], skipSpecialTokens: Bool) -> String {
                upstream.decode(tokens: tokenIds, skipSpecialTokens: skipSpecialTokens)
            }

            func convertTokenToId(_ token: String) -> Int? {
                upstream.convertTokenToId(token)
            }

            func convertIdToToken(_ id: Int) -> String? {
                upstream.convertIdToToken(id)
            }

            var bosToken: String? { upstream.bosToken }
            var eosToken: String? { upstream.eosToken }
            var unknownToken: String? { upstream.unknownToken }

            func applyChatTemplate(
                messages: [[String: any Sendable]],
                tools: [[String: any Sendable]]?,
                additionalContext: [String: any Sendable]?
            ) throws -> [Int] {
                do {
                    return try upstream.applyChatTemplate(
                        messages: messages,
                        tools: tools,
                        additionalContext: additionalContext
                    )
                } catch {
                    if let tokenizerError = error as? Tokenizers.TokenizerError {
                        switch tokenizerError {
                        case .missingChatTemplate:
                            throw MLXLMCommon.TokenizerError.missingChatTemplate
                        default:
                            throw error
                        }
                    }
                    throw error
                }
            }
        }

        let upstream = try await AutoTokenizer.from(modelFolder: directory)
        return Bridge(upstream: upstream)
    }
}

// MARK: - Main

@main
struct MLXSmokeTest {
    static func main() async {
        print("=== MLX Backend Smoke Test ===")
        print("")

        var tested = 0
        var loadedCount = 0
        var failedCount = 0
        var skippedCount = 0
        var mlxModelCount = 0

        let config = HuggingFaceCacheConfiguration()
        let scanner = CacheScanner(configuration: config)
        let hubDir = config.hubCacheDirectory

        print("Hub directory: \(hubDir.path)")

        // Step 1: Discover all cached models
        let details = scanner.discoverRepositoryDetails()
        guard !details.isEmpty else {
            print("ERROR: No model repositories found in cache.")
            return
        }

        print("Found \(details.count) model repositories:")
        for repo in details.sorted(by: { $0.totalSize < $1.totalSize }) {
            print("  \(repo.repositoryID) - \(HuggingFaceCacheConfiguration.formatBytes(repo.totalSize))")
        }
        print("")

        // Step 2: Try loading each model, smallest first
        let sortedRepos = details.sorted { $0.totalSize < $1.totalSize }
        for repo in sortedRepos {
            guard let firstHash = repo.snapshots.first,
                  let files = repo.snapshotFiles[firstHash] else { continue }

            // Only try models with .safetensors files (MLX models)
            guard files.contains(where: { $0.hasSuffix(".safetensors") }) else { continue }
            mlxModelCount += 1

            // Build snapshot directory path
            let repoDir = hubDir
                .appendingPathComponent(repo.directoryName)
                .appendingPathComponent("snapshots")
                .appendingPathComponent(firstHash)

            // Read model_type from config.json
            let configPath = repoDir.appendingPathComponent("config.json")
            var modelType = "UNKNOWN"
            if let configData = try? Data(contentsOf: configPath),
               let config = try? JSONSerialization.jsonObject(with: configData) as? [String: Any],
               let type = config["model_type"] as? String {
                modelType = type
            }

            tested += 1
            print("---")
            print("Testing: \(repo.repositoryID)")
            print("  Size: \(HuggingFaceCacheConfiguration.formatBytes(repo.totalSize))")
            print("  Model type: \(modelType)")
            print("  Directory: \(repoDir.path)")

            // Check for tokenizer files (needed for generation)
            let hasTokenizer = files.contains { $0.hasSuffix(".json") && ($0.contains("tokenizer") || $0.contains("vocab")) }
            guard hasTokenizer else {
                print("  SKIP: No tokenizer files found")
                skippedCount += 1
                continue
            }

            do {
                let loadStart = Date()
                print("  Loading model...")
                let container = try await loadModelContainer(
                    from: repoDir,
                    using: HuggingFaceTokenizerLoader()
                )
                let loadElapsed = Date().timeIntervalSince(loadStart)
                print("  Loaded in \(String(format: "%.1f", loadElapsed))s")

                // Step 3: Generate
                print("  Generating...")
                let input = try await container.prepare(
                    input: UserInput(prompt: "The meaning of life is")
                )
                var params = GenerateParameters()
                params.maxTokens = 20

                let genStart = Date()
                let stream = try await container.generate(input: input, parameters: params)
                var output = ""
                for try await generation in stream {
                    if case .chunk(let text) = generation {
                        output += text
                    }
                }
                let genElapsed = Date().timeIntervalSince(genStart)
                let tokenCount = output.count  // rough estimate
                let tokPerSec = Double(tokenCount) / max(genElapsed, 0.001)

                print("  Output: \"\(output.trimmingCharacters(in: .whitespacesAndNewlines))\"")
                print("  Generation: \(String(format: "%.1f", genElapsed))s, ~\(tokPerSec) tok/s")
                print("  ✅ Loaded!")
                loadedCount += 1
            } catch {
                print("  FAILED: \(error.localizedDescription)")
                failedCount += 1
            }
        }

        print("---")
        print("")
        print("=== AUDIT COMPLETE ===")
        print("Total MLX models: \(mlxModelCount)")
        print("Tested: \(tested) | Loaded: \(loadedCount) | Failed: \(failedCount) | Skipped: \(skippedCount)")
    }
}
