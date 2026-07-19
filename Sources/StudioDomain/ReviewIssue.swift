import Foundation

/// Types of review issues.
public enum ReviewIssueType: String, Codable, Sendable, CaseIterable {
    case uncertainSpeaker = "Uncertain Speaker"
    case duplicateCharacter = "Duplicate Character"
    case missingVoice = "Missing Voice"
    case missingAudio = "Missing Audio"
    case staleDialogue = "Stale Dialogue"
    case failedGeneration = "Failed Generation"
    case abruptSceneTransition = "Abrupt Scene Transition"
    case exportValidation = "Export Validation"
}

/// Severity of a review issue.
public enum IssueSeverity: String, Codable, Sendable, Comparable, CaseIterable {
    case info = "Info"
    case warning = "Warning"
    case error = "Error"

    public var order: Int {
        switch self {
        case .info: 0
        case .warning: 1
        case .error: 2
        }
    }

    public static func < (lhs: IssueSeverity, rhs: IssueSeverity) -> Bool {
        lhs.order < rhs.order
    }
}

/// A flagged issue that needs review.
public struct ReviewIssue: Identifiable, Codable, Sendable {
    public typealias ID = TypedID<ReviewIssue>

    public let id: ID
    public var type: ReviewIssueType
    public var title: String
    public var description: String
    public var relatedStage: WorkflowStage
    /// Deep-link identifier: format like "chapter:<uuid>", "scene:<uuid>", "block:<uuid>", "character:<uuid>"
    public var relatedEntityID: String
    public var severity: IssueSeverity
    public var isResolved: Bool
    public var createdAt: Date

    public init(
        id: ID = ID(),
        type: ReviewIssueType,
        title: String,
        description: String = "",
        relatedStage: WorkflowStage,
        relatedEntityID: String,
        severity: IssueSeverity = .warning,
        isResolved: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.relatedStage = relatedStage
        self.relatedEntityID = relatedEntityID
        self.severity = severity
        self.isResolved = isResolved
        self.createdAt = createdAt
    }
}
