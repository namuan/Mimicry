import Foundation

/// Display model for a review issue in the UI.
public struct ReviewIssueViewState: Identifiable, Sendable {
    public let id: ReviewIssue.ID
    public var title: String
    public var description: String
    public var type: ReviewIssueType
    public var severity: IssueSeverity
    public var relatedStage: WorkflowStage
    public var relatedEntityID: String
    public var isResolved: Bool

    public init(issue: ReviewIssue) {
        self.id = issue.id
        self.title = issue.title
        self.description = issue.description
        self.type = issue.type
        self.severity = issue.severity
        self.relatedStage = issue.relatedStage
        self.relatedEntityID = issue.relatedEntityID
        self.isResolved = issue.isResolved
    }
}
