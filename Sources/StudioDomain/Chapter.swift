import Foundation

/// A chapter in the book.
public struct Chapter: Identifiable, Codable, Sendable {
    public typealias ID = TypedID<Chapter>

    public let id: ID
    public var title: String
    public var number: Int
    public var order: Int
    public var rawText: String
    public var sceneIDs: [Scene.ID]
    public var isIncluded: Bool

    public init(
        id: ID = ID(),
        title: String,
        number: Int,
        order: Int = 0,
        rawText: String = "",
        sceneIDs: [Scene.ID] = [],
        isIncluded: Bool = true
    ) {
        self.id = id
        self.title = title
        self.number = number
        self.order = order
        self.rawText = rawText
        self.sceneIDs = sceneIDs
        self.isIncluded = isIncluded
    }
}
