import Foundation

/// The scope of a generation operation.
public enum GenerationScope: String, Codable, Sendable, CaseIterable {
    case line = "Line"
    case scene = "Scene"
    case chapter = "Chapter"
    case book = "Book"
}

/// Type of generation job.
public enum JobType: String, Codable, Sendable, CaseIterable {
    case epubImport = "EPUB Import"
    case sceneDetection = "Scene Detection"
    case characterAnalysis = "Character Analysis"
    case dialogueAttribution = "Dialogue Attribution"
    case voiceGeneration = "Voice Generation"
    case speechGeneration = "Speech Generation"
    case soundtrackGeneration = "Soundtrack Generation"
    case audioMixing = "Audio Mixing"
    case export = "Export"
}

/// Status of a generation job.
public enum JobStatus: String, Codable, Sendable, CaseIterable {
    case queued = "Queued"
    case running = "Running"
    case completed = "Completed"
    case failed = "Failed"
    case cancelled = "Cancelled"
}

/// Tracks a long-running generation or processing job.
public struct GenerationJob: Identifiable, Codable, Sendable {
    public typealias ID = TypedID<GenerationJob>

    public let id: ID
    public var type: JobType
    public var scope: GenerationScope
    public var status: JobStatus
    public var progress: Double
    public var estimatedDuration: TimeInterval?
    public var createdAt: Date
    public var startedAt: Date?
    public var completedAt: Date?
    public var errorMessage: String?
    public var targetIDs: [String]
    public var logMessages: [String]

    public init(
        id: ID = ID(),
        type: JobType,
        scope: GenerationScope = .scene,
        status: JobStatus = .queued,
        progress: Double = 0,
        estimatedDuration: TimeInterval? = nil,
        createdAt: Date = Date(),
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        errorMessage: String? = nil,
        targetIDs: [String] = [],
        logMessages: [String] = []
    ) {
        self.id = id
        self.type = type
        self.scope = scope
        self.status = status
        self.progress = progress
        self.estimatedDuration = estimatedDuration
        self.createdAt = createdAt
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.errorMessage = errorMessage
        self.targetIDs = targetIDs
        self.logMessages = logMessages
    }
}
