import Foundation

/// A scene within a chapter.
public struct Scene: Identifiable, Codable, Sendable {
    public typealias ID = TypedID<Scene>

    public let id: ID
    public let chapterID: Chapter.ID
    public var title: String
    public var summary: String
    public var rawText: String
    public var order: Int
    public var blockIDs: [ScriptBlock.ID]
    public var sceneBoundaryConfidence: Double?
    public var location: String?
    public var mood: String?

    public init(
        id: ID = ID(),
        chapterID: Chapter.ID,
        title: String,
        summary: String = "",
        rawText: String = "",
        order: Int = 0,
        blockIDs: [ScriptBlock.ID] = [],
        sceneBoundaryConfidence: Double? = nil,
        location: String? = nil,
        mood: String? = nil
    ) {
        self.id = id
        self.chapterID = chapterID
        self.title = title
        self.summary = summary
        self.rawText = rawText
        self.order = order
        self.blockIDs = blockIDs
        self.sceneBoundaryConfidence = sceneBoundaryConfidence
        self.location = location
        self.mood = mood
    }
}
