import Foundation

/// Predefined model configurations shipped with the application.
public enum BundledModelCatalogue {
    /// All known model specifications.
    public static let allModels: [HuggingFaceModelSpecification] = [
        // LLM for scene detection
        HuggingFaceModelSpecification(
            id: "scene-detection-mlx",
            displayName: "Qwen 3 4B MLX",
            purpose: .sceneDetection,
            backend: .mlx,
            repositoryID: "mlx-community/Qwen3-4B-Instruct-4bit",
            revision: "main",
            requiredFiles: [
                RequiredModelFile(path: "config.json", expectedSize: 1024),
                RequiredModelFile(path: "tokenizer.json", expectedSize: 2_000_000),
                RequiredModelFile(path: "tokenizer_config.json", expectedSize: 1024),
                RequiredModelFile(path: "model.safetensors.index.json", expectedSize: 4096),
                RequiredModelFile(path: "model-00001-of-00002.safetensors", expectedSize: 1_300_000_000),
                RequiredModelFile(path: "model-00002-of-00002.safetensors", expectedSize: 1_300_000_000),
            ],
            contextLength: 32768,
            estimatedMemoryBytes: 4_000_000_000,
            minimumMemoryBytes: 3_000_000_000,
            licenseIdentifier: "Apache-2.0",
            gated: false
        ),
        // LLM for scene detection (llama.cpp)
        HuggingFaceModelSpecification(
            id: "scene-detection-llama",
            displayName: "Qwen 3 4B GGUF Q4_K_M",
            purpose: .sceneDetection,
            backend: .llamaCpp,
            repositoryID: "bartowski/Qwen3-4B-Instruct-GGUF",
            revision: "main",
            requiredFiles: [
                RequiredModelFile(path: "Qwen3-4B-Instruct-Q4_K_M.gguf", expectedSize: 2_800_000_000),
            ],
            contextLength: 32768,
            estimatedMemoryBytes: 3_500_000_000,
            minimumMemoryBytes: 3_000_000_000,
            licenseIdentifier: "Apache-2.0",
            gated: false
        ),
        // LLM for character detection
        HuggingFaceModelSpecification(
            id: "character-detection-mlx",
            displayName: "Qwen 3 4B MLX (Character)",
            purpose: .characterDetection,
            backend: .mlx,
            repositoryID: "mlx-community/Qwen3-4B-Instruct-4bit",
            revision: "main",
            requiredFiles: [
                RequiredModelFile(path: "config.json"),
                RequiredModelFile(path: "tokenizer.json"),
                RequiredModelFile(path: "tokenizer_config.json"),
                RequiredModelFile(path: "model.safetensors.index.json"),
                RequiredModelFile(path: "model-00001-of-00002.safetensors", expectedSize: 1_300_000_000),
                RequiredModelFile(path: "model-00002-of-00002.safetensors", expectedSize: 1_300_000_000),
            ],
            contextLength: 32768,
            estimatedMemoryBytes: 4_000_000_000,
            licenseIdentifier: "Apache-2.0",
            gated: false
        ),
        // LLM for dialogue attribution
        HuggingFaceModelSpecification(
            id: "dialogue-attribution-mlx",
            displayName: "Qwen 3 4B MLX (Dialogue)",
            purpose: .dialogueAttribution,
            backend: .mlx,
            repositoryID: "mlx-community/Qwen3-4B-Instruct-4bit",
            revision: "main",
            requiredFiles: [
                RequiredModelFile(path: "config.json"),
                RequiredModelFile(path: "tokenizer.json"),
                RequiredModelFile(path: "tokenizer_config.json"),
                RequiredModelFile(path: "model.safetensors.index.json"),
                RequiredModelFile(path: "model-00001-of-00002.safetensors"),
                RequiredModelFile(path: "model-00002-of-00002.safetensors"),
            ],
            contextLength: 32768,
            estimatedMemoryBytes: 4_000_000_000,
            licenseIdentifier: "Apache-2.0",
            gated: false
        ),
        // Speech (TTS) — placeholder for now
        HuggingFaceModelSpecification(
            id: "speech-mlx",
            displayName: "Speech TTS (TBD)",
            purpose: .speech,
            backend: .mlx,
            repositoryID: "mlx-community/speech-model-placeholder",
            revision: "main",
            requiredFiles: [
                RequiredModelFile(path: "config.json"),
                RequiredModelFile(path: "model.safetensors"),
            ],
            estimatedMemoryBytes: 2_000_000_000,
            licenseIdentifier: "TBD",
            gated: false
        ),
        // Qwen3 TTS 0.6B CustomVoice — named speakers + style control
        HuggingFaceModelSpecification(
            id: "qwen3-tts-0.6b-customvoice",
            displayName: "Qwen3 TTS 0.6B CustomVoice",
            purpose: .speech,
            backend: .mlx,
            repositoryID: "Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice",
            revision: "main",
            requiredFiles: [
                RequiredModelFile(path: "config.json"),
                RequiredModelFile(path: "model.safetensors", expectedSize: 1_800_000_000),
                RequiredModelFile(path: "vocab.json"),
                RequiredModelFile(path: "merges.txt"),
            ],
            estimatedMemoryBytes: 2_500_000_000,
            licenseIdentifier: "Apache-2.0",
            gated: false
        ),
        // Qwen3 TTS 0.6B — voice description → styled speech
        HuggingFaceModelSpecification(
            id: "qwen3-tts-voice-design",
            displayName: "Qwen3 TTS CustomVoice (Voice Design)",
            purpose: .voiceDesign,
            backend: .mlx,
            repositoryID: "Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice",
            revision: "main",
            requiredFiles: [
                RequiredModelFile(path: "config.json"),
                RequiredModelFile(path: "model.safetensors", expectedSize: 1_800_000_000),
                RequiredModelFile(path: "vocab.json"),
                RequiredModelFile(path: "merges.txt"),
            ],
            estimatedMemoryBytes: 2_500_000_000,
            licenseIdentifier: "Apache-2.0",
            gated: false
        ),
    ]

    /// Find models by purpose.
    public static func models(for purpose: ModelPurpose) -> [HuggingFaceModelSpecification] {
        allModels.filter { $0.purpose == purpose }
    }

    /// Find models by backend.
    public static func models(for backend: InferenceBackend) -> [HuggingFaceModelSpecification] {
        allModels.filter { $0.backend == backend }
    }

    /// Get a specific model by ID.
    public static func model(id: String) -> HuggingFaceModelSpecification? {
        allModels.first { $0.id == id }
    }
}
