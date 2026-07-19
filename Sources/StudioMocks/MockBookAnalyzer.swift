import Foundation
import StudioDomain
import StudioServices

/// Mock book analyzer that returns pre-built data with simulated AI processing.
public final class MockBookAnalyzer: BookAnalyzing, @unchecked Sendable {
    public init() {}

    public func detectScenes(in chapter: Chapter) async throws -> [Scene] {
        try await simulateWork(duration: 1.5)
        let project = MockSampleData.buildProject()
        return project.scenes.filter { $0.chapterID == chapter.id }
    }

    public func detectCharacters(in scenes: [Scene]) async throws -> [Character] {
        try await simulateWork(duration: 2.0)
        let project = MockSampleData.buildProject()
        return project.characters
    }

    public func detectDuplicateCandidates(_ characters: [Character]) async throws -> [(Character, Character, Double)] {
        try await simulateWork(duration: 1.0)
        let project = MockSampleData.buildProject()
        guard let elena = project.characters.first(where: { $0.name.contains("Elena") }),
              let doctor = project.characters.first(where: { $0.name.contains("Dr.") })
        else { return [] }
        return [(elena, doctor, 0.82)]
    }

    public func attributeDialogue(in scene: Scene, characters: [Character]) async throws -> [ScriptBlock] {
        try await simulateWork(duration: 1.0)
        let project = MockSampleData.buildProject()
        return project.blocks.filter { $0.sceneID == scene.id }
    }

    private func simulateWork(duration: TimeInterval) async throws {
        let steps = Int(duration / 0.3)
        for _ in 0..<steps {
            try await Task.sleep(for: .milliseconds(300))
        }
    }
}
