import Foundation

/// The sequential workflow stages for producing an audiobook.
public enum WorkflowStage: String, CaseIterable, Codable, Sendable, Comparable {
    case `import` = "Import"
    case structure = "Structure"
    case characters = "Characters"
    case script = "Script"
    case voices = "Voices"
    case soundDesign = "Sound Design"
    case generate = "Generate"
    case review = "Review"
    case export = "Export"

    public var order: Int {
        switch self {
        case .import: 0
        case .structure: 1
        case .characters: 2
        case .script: 3
        case .voices: 4
        case .soundDesign: 5
        case .generate: 6
        case .review: 7
        case .export: 8
        }
    }

    public static func < (lhs: WorkflowStage, rhs: WorkflowStage) -> Bool {
        lhs.order < rhs.order
    }

    /// Stages that depend on this stage's output.
    public var downstreamStages: [WorkflowStage] {
        let all = WorkflowStage.allCases
        guard let idx = all.firstIndex(of: self) else { return [] }
        return Array(all[(idx + 1)...])
    }
}

/// Status of a workflow stage.
public enum WorkflowStageStatus: String, Codable, Sendable {
    case notStarted = "Not Started"
    case available = "Available"
    case inProgress = "In Progress"
    case needsReview = "Needs Review"
    case complete = "Complete"
    case outOfDate = "Out of Date"
    case failed = "Failed"
}

/// Tracks stage-level state within a project.
public struct WorkflowStageInfo: Codable, Sendable, Identifiable {
    public var id: WorkflowStage { stage }
    public let stage: WorkflowStage
    public var status: WorkflowStageStatus
    public var lastModified: Date
    public var errorMessage: String?

    public init(
        stage: WorkflowStage,
        status: WorkflowStageStatus = .notStarted,
        lastModified: Date = Date(),
        errorMessage: String? = nil
    ) {
        self.stage = stage
        self.status = status
        self.lastModified = lastModified
        self.errorMessage = errorMessage
    }
}
