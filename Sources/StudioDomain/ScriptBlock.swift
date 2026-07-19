import Foundation

/// Type of content in a script block.
public enum BlockType: String, Codable, Sendable, CaseIterable {
    case narration = "Narration"
    case dialogue = "Dialogue"
    case thought = "Thought"
}

/// A single block of text in the production script.
public struct ScriptBlock: Identifiable, Codable, Sendable {
    public typealias ID = TypedID<ScriptBlock>

    public let id: ID
    public let sceneID: Scene.ID
    public var type: BlockType
    public var productionText: String
    public var sourceText: String
    public var speakerID: Character.ID?
    public var speakerConfidence: Double?
    public var isExcluded: Bool
    public var order: Int
    public var performanceDirection: String?
    public var speakingRate: Double?

    public init(
        id: ID = ID(),
        sceneID: Scene.ID,
        type: BlockType = .narration,
        productionText: String = "",
        sourceText: String = "",
        speakerID: Character.ID? = nil,
        speakerConfidence: Double? = nil,
        isExcluded: Bool = false,
        order: Int = 0,
        performanceDirection: String? = nil,
        speakingRate: Double? = nil
    ) {
        self.id = id
        self.sceneID = sceneID
        self.type = type
        self.productionText = productionText
        self.sourceText = sourceText
        self.speakerID = speakerID
        self.speakerConfidence = speakerConfidence
        self.isExcluded = isExcluded
        self.order = order
        self.performanceDirection = performanceDirection
        self.speakingRate = speakingRate
    }

    /// Whether the block has a resolved speaker.
    public var hasResolvedSpeaker: Bool {
        type == .narration || speakerID != nil
    }

    /// Whether the block needs speaker resolution (dialogue without a known speaker).
    public var needsSpeakerResolution: Bool {
        type == .dialogue && speakerID == nil
    }
}
