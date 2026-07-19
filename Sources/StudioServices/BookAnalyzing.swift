import Foundation
import StudioDomain

/// AI-powered book analysis protocol (scene detection, character extraction).
public protocol BookAnalyzing: Sendable {
    func detectScenes(in chapter: Chapter) async throws -> [Scene]
    func detectCharacters(in scenes: [Scene]) async throws -> [Character]
    func detectDuplicateCandidates(_ characters: [Character]) async throws -> [(Character, Character, Double)]
    func attributeDialogue(in scene: Scene, characters: [Character]) async throws -> [ScriptBlock]
}
