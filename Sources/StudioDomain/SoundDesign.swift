import Foundation

/// Sound design settings for a scene.
public struct SoundDesignSettings: Codable, Sendable {
    public let sceneID: Scene.ID
    public var musicPrompt: String
    public var ambiencePrompt: String
    public var musicVolume: Double
    public var ambienceVolume: Double
    public var fadeInDuration: TimeInterval
    public var fadeOutDuration: TimeInterval
    public var dialogueDucking: Bool
    public var generatedMusicData: Data?
    public var generatedAmbienceData: Data?
    public var musicDuration: TimeInterval?
    public var ambienceDuration: TimeInterval?
    public var musicIsLoopable: Bool
    public var ambienceIsLoopable: Bool
    public var generationMetadata: [String: String]

    public init(
        sceneID: Scene.ID,
        musicPrompt: String = "",
        ambiencePrompt: String = "",
        musicVolume: Double = 0.7,
        ambienceVolume: Double = 0.5,
        fadeInDuration: TimeInterval = 0.5,
        fadeOutDuration: TimeInterval = 1.0,
        dialogueDucking: Bool = true,
        generatedMusicData: Data? = nil,
        generatedAmbienceData: Data? = nil,
        musicDuration: TimeInterval? = nil,
        ambienceDuration: TimeInterval? = nil,
        musicIsLoopable: Bool = false,
        ambienceIsLoopable: Bool = false,
        generationMetadata: [String: String] = [:]
    ) {
        self.sceneID = sceneID
        self.musicPrompt = musicPrompt
        self.ambiencePrompt = ambiencePrompt
        self.musicVolume = musicVolume
        self.ambienceVolume = ambienceVolume
        self.fadeInDuration = fadeInDuration
        self.fadeOutDuration = fadeOutDuration
        self.dialogueDucking = dialogueDucking
        self.generatedMusicData = generatedMusicData
        self.generatedAmbienceData = generatedAmbienceData
        self.musicDuration = musicDuration
        self.ambienceDuration = ambienceDuration
        self.musicIsLoopable = musicIsLoopable
        self.ambienceIsLoopable = ambienceIsLoopable
        self.generationMetadata = generationMetadata
    }
}
