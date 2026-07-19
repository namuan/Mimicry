import Foundation

/// A generated or selected voice profile for a character.
public struct VoiceProfile: Identifiable, Codable, Sendable {
    public typealias ID = TypedID<VoiceProfile>

    public let id: ID
    public var name: String
    public var description: String
    public var accent: String?
    public var ageRange: String?
    public var tone: String?
    public var sampleText: String?
    public var seed: UInt64?
    public var isNarratorVoice: Bool
    public var previewAudioData: Data?
    public var generationMetadata: [String: String]

    public init(
        id: ID = ID(),
        name: String = "",
        description: String = "",
        accent: String? = nil,
        ageRange: String? = nil,
        tone: String? = nil,
        sampleText: String? = nil,
        seed: UInt64? = nil,
        isNarratorVoice: Bool = false,
        previewAudioData: Data? = nil,
        generationMetadata: [String: String] = [:]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.accent = accent
        self.ageRange = ageRange
        self.tone = tone
        self.sampleText = sampleText
        self.seed = seed
        self.isNarratorVoice = isNarratorVoice
        self.previewAudioData = previewAudioData
        self.generationMetadata = generationMetadata
    }
}
