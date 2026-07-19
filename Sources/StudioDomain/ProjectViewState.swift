import Foundation

/// The main view state consumed by the UI. Re-maps domain types for display.
public struct ProjectViewState: Sendable {
    public var title: String
    public var author: String
    public var coverImageData: Data?
    public var chapters: [Chapter]
    public var characters: [Character]
    public var scenes: [Scene]
    public var blocks: [ScriptBlock]
    public var voiceProfiles: [VoiceProfile]
    public var soundDesigns: [SoundDesignSettings]
    public var generationJobs: [GenerationJob]
    public var reviewIssues: [ReviewIssue]
    public var workflowStages: [WorkflowStageInfo]
    public var exportConfig: ExportConfiguration
    public var modelAssignments: [ModelAssignment]

    public init(
        title: String = "",
        author: String = "",
        coverImageData: Data? = nil,
        chapters: [Chapter] = [],
        characters: [Character] = [],
        scenes: [Scene] = [],
        blocks: [ScriptBlock] = [],
        voiceProfiles: [VoiceProfile] = [],
        soundDesigns: [SoundDesignSettings] = [],
        generationJobs: [GenerationJob] = [],
        reviewIssues: [ReviewIssue] = [],
        workflowStages: [WorkflowStageInfo] = [],
        exportConfig: ExportConfiguration = ExportConfiguration(),
        modelAssignments: [ModelAssignment] = []
    ) {
        self.title = title
        self.author = author
        self.coverImageData = coverImageData
        self.chapters = chapters
        self.characters = characters
        self.scenes = scenes
        self.blocks = blocks
        self.voiceProfiles = voiceProfiles
        self.soundDesigns = soundDesigns
        self.generationJobs = generationJobs
        self.reviewIssues = reviewIssues
        self.workflowStages = workflowStages
        self.exportConfig = exportConfig
        self.modelAssignments = modelAssignments
    }
}
