import Foundation
import StudioDomain

/// Audio mixing protocol.
public protocol AudioMixing: Sendable {
    func mixScene(
        speechBlocks: [(ScriptBlock, Data)],
        soundtrack: GeneratedSceneAudio?,
        settings: SoundDesignSettings?
    ) async throws -> Data

    func mixChapter(sceneAudio: [Data]) async throws -> Data
}
