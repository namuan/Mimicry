import Foundation

/// The root entity for an audiobook production project.
public struct Project: Identifiable, Codable, Sendable {
    public typealias ID = TypedID<Project>

    public let id: ID
    public var title: String
    public var author: String
    public var coverImageData: Data?
    public var chapters: [Chapter]
    public var characters: [Character]
    public var scenes: [Scene]
    public var blocks: [ScriptBlock]
    public var voiceProfiles: [VoiceProfile]
    public var soundDesigns: [SoundDesignSettings]
    public var narratorID: Character.ID?
    public var workflowStages: [WorkflowStageInfo]
    public var reviewIssues: [ReviewIssue]
    public var generationJobs: [GenerationJob]
    public var exportConfig: ExportConfiguration
    public var modelAssignments: [ModelAssignment]
    public var createdAt: Date
    public var modifiedAt: Date

    public init(
        id: ID = ID(),
        title: String = "",
        author: String = "",
        coverImageData: Data? = nil,
        chapters: [Chapter] = [],
        characters: [Character] = [],
        scenes: [Scene] = [],
        blocks: [ScriptBlock] = [],
        voiceProfiles: [VoiceProfile] = [],
        soundDesigns: [SoundDesignSettings] = [],
        narratorID: Character.ID? = nil,
        workflowStages: [WorkflowStageInfo] = [],
        reviewIssues: [ReviewIssue] = [],
        generationJobs: [GenerationJob] = [],
        exportConfig: ExportConfiguration = ExportConfiguration(),
        modelAssignments: [ModelAssignment] = [],
        createdAt: Date = Date(),
        modifiedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.author = author
        self.coverImageData = coverImageData
        self.chapters = chapters
        self.characters = characters
        self.scenes = scenes
        self.blocks = blocks
        self.voiceProfiles = voiceProfiles
        self.soundDesigns = soundDesigns
        self.narratorID = narratorID
        self.workflowStages = workflowStages
        self.reviewIssues = reviewIssues
        self.generationJobs = generationJobs
        self.exportConfig = exportConfig
        self.modelAssignments = modelAssignments
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    /// Creates view state from the project for UI consumption.
    public func makeViewState() -> ProjectViewState {
        ProjectViewState(
            title: title,
            author: author,
            coverImageData: coverImageData,
            chapters: chapters,
            characters: characters,
            scenes: scenes,
            blocks: blocks,
            voiceProfiles: voiceProfiles,
            soundDesigns: soundDesigns,
            generationJobs: generationJobs,
            reviewIssues: reviewIssues,
            workflowStages: workflowStages,
            exportConfig: exportConfig,
            modelAssignments: modelAssignments
        )
    }

    // MARK: - Convenience accessors

    public func chapter(for id: Chapter.ID) -> Chapter? {
        chapters.first { $0.id == id }
    }

    public func scene(for id: Scene.ID) -> Scene? {
        scenes.first { $0.id == id }
    }

    public func character(for id: Character.ID) -> Character? {
        characters.first { $0.id == id }
    }

    public func block(for id: ScriptBlock.ID) -> ScriptBlock? {
        blocks.first { $0.id == id }
    }

    public func voiceProfile(for id: VoiceProfile.ID) -> VoiceProfile? {
        voiceProfiles.first { $0.id == id }
    }

    public func soundDesign(for sceneID: Scene.ID) -> SoundDesignSettings? {
        soundDesigns.first { $0.sceneID == sceneID }
    }

    public func blocks(for sceneID: Scene.ID) -> [ScriptBlock] {
        blocks.filter { $0.sceneID == sceneID }.sorted { $0.order < $1.order }
    }

    public func scenes(for chapterID: Chapter.ID) -> [Scene] {
        scenes.filter { $0.chapterID == chapterID }.sorted { $0.order < $1.order }
    }

    public func stage(for stage: WorkflowStage) -> WorkflowStageInfo? {
        workflowStages.first { $0.stage == stage }
    }

    /// Update a workflow stage status and mark downstream stages as out of date.
    public mutating func updateStage(_ stage: WorkflowStage, status: WorkflowStageStatus) {
        if let idx = workflowStages.firstIndex(where: { $0.stage == stage }) {
            workflowStages[idx].status = status
            workflowStages[idx].lastModified = Date()
        } else {
            workflowStages.append(WorkflowStageInfo(
                stage: stage,
                status: status,
                lastModified: Date()
            ))
        }

        // Mark all downstream stages as out of date if this change invalidates them
        if status == .complete || status == .needsReview {
            for downstreamStage in stage.downstreamStages {
                if let idx = workflowStages.firstIndex(where: { $0.stage == downstreamStage }) {
                    if workflowStages[idx].status == .complete {
                        workflowStages[idx].status = .outOfDate
                        workflowStages[idx].lastModified = Date()
                    }
                }
            }
        }

        modifiedAt = Date()
    }
}
