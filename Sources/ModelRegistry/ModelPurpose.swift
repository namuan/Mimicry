import Foundation

/// The purpose a model serves in the audiobook production pipeline.
public enum ModelPurpose: String, Codable, Sendable, CaseIterable, Hashable {
    case sceneDetection = "Scene Detection"
    case characterDetection = "Character Detection"
    case dialogueAttribution = "Dialogue Attribution"
    case speech = "Speech"
    case voiceDesign = "Voice Design"
    case backgroundAudio = "Background Audio"
    case unknown = "General Purpose"

    /// Human-readable description.
    public var description: String {
        switch self {
        case .sceneDetection: "Identifies scene boundaries within chapters"
        case .characterDetection: "Extracts characters and their attributes from text"
        case .dialogueAttribution: "Attributs dialogue blocks to specific characters"
        case .speech: "Generates spoken dialogue from text"
        case .voiceDesign: "Creates and customizes voice profiles"
        case .backgroundAudio: "Generates music and ambient soundscapes"
        case .unknown: "Auto-discovered model with unknown purpose"
        }
    }

    /// Infer the likely purpose from the repository ID and files.
    /// Heuristic-based: inspects the lowercased repo ID and file extensions for keywords.
    public static func infer(
        from repositoryID: String,
        files: [String]
    ) -> ModelPurpose {
        let lower = repositoryID.lowercased()
        let lowerFiles = files.map { $0.lowercased() }
        let allText = (lower + " " + lowerFiles.joined(separator: " ")).lowercased()

        // Speech / TTS models
        if allText.contains("tts") || allText.contains("speech") || allText.contains("bark") || allText.contains("vits") {
            return .speech
        }

        // Voice design / cloning
        if allText.contains("voice") || allText.contains("speaker") {
            return .voiceDesign
        }

        // Music / audio generation
        if allText.contains("music") || allText.contains("musicgen") || allText.contains("audiogen")
            || allText.contains("sound") || allText.contains("ambient") {
            return .backgroundAudio
        }

        // General LLM — can be used for text analysis tasks
        // Models with "instruct", "chat", or common LLM names default to dialogue attribution
        // since that's the most general text-analysis task
        if allText.contains("instruct") || allText.contains("chat")
            || allText.contains("qwen") || allText.contains("llama")
            || allText.contains("mistral") || allText.contains("phi")
            || allText.contains("gemma") || allText.contains("deepseek") {
            return .dialogueAttribution
        }

        return .unknown
    }
}
