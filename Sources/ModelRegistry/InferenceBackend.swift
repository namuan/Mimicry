import Foundation

/// Supported inference backends for running models.
public enum InferenceBackend: String, Codable, Sendable, CaseIterable, Hashable {
    case mlx = "MLX"
    case llamaCpp = "llama.cpp"

    /// Display name for UI.
    public var displayName: String {
        switch self {
        case .mlx: "MLX Swift"
        case .llamaCpp: "llama.cpp"
        }
    }

    /// Typical file extension for model files.
    public var expectedExtensions: [String] {
        switch self {
        case .mlx: ["safetensors", "json"]
        case .llamaCpp: ["gguf"]
        }
    }
}
