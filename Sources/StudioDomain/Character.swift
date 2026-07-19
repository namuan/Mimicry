import Foundation

/// A character in the book.
public struct Character: Identifiable, Codable, Sendable {
    public typealias ID = TypedID<Character>

    public let id: ID
    public var name: String
    public var aliases: [String]
    public var isNarrator: Bool
    public var description: String
    public var sceneAppearances: [Scene.ID]
    public var voiceProfileID: VoiceProfile.ID?
    public var notes: String

    public init(
        id: ID = ID(),
        name: String,
        aliases: [String] = [],
        isNarrator: Bool = false,
        description: String = "",
        sceneAppearances: [Scene.ID] = [],
        voiceProfileID: VoiceProfile.ID? = nil,
        notes: String = ""
    ) {
        self.id = id
        self.name = name
        self.aliases = aliases
        self.isNarrator = isNarrator
        self.description = description
        self.sceneAppearances = sceneAppearances
        self.voiceProfileID = voiceProfileID
        self.notes = notes
    }

    /// All known names including aliases.
    public var allNames: [String] {
        [name] + aliases
    }
}
