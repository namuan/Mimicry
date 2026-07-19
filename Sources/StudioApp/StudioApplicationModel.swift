import SwiftUI
import StudioDomain
import StudioServices
import StudioMocks

/// The main application model conforming to SPIKES.md specification.
@MainActor
public final class StudioApplicationModel: ObservableObject {
    // MARK: - Published state
    @Published var projectViewState: ProjectViewState?
    @Published var selectedStage: WorkflowStage = .import
    @Published var selectedChapterID: Chapter.ID?
    @Published var selectedSceneID: StudioDomain.Scene.ID?
    @Published var selectedBlockID: ScriptBlock.ID?
    @Published var activeJobs: [JobViewState] = []
    @Published var reviewIssues: [ReviewIssueViewState] = []
    @Published var isProcessing = false
    @Published var statusMessage: String?

    // MARK: - Services
    private let repository: any ProjectRepository
    private let epubImporter: any EPUBImporting
    private let bookAnalyzer: any BookAnalyzing
    private let languageModel: any LanguageModelServing
    private let voiceGenerator: any VoiceGenerating & VoiceProfileGenerating
    private let speechGenerator: any SpeechGenerating
    private let soundtrackGenerator: any SoundtrackGenerating
    private let audioMixer: any AudioMixing
    private let exporter: any Exporting

    private var project: Project?

    // MARK: - Init

    public init(
        repository: any ProjectRepository,
        epubImporter: any EPUBImporting,
        bookAnalyzer: any BookAnalyzing,
        languageModel: any LanguageModelServing,
        voiceGenerator: any VoiceGenerating & VoiceProfileGenerating,
        speechGenerator: any SpeechGenerating,
        soundtrackGenerator: any SoundtrackGenerating,
        audioMixer: any AudioMixing,
        exporter: any Exporting
    ) {
        self.repository = repository
        self.epubImporter = epubImporter
        self.bookAnalyzer = bookAnalyzer
        self.languageModel = languageModel
        self.voiceGenerator = voiceGenerator
        self.speechGenerator = speechGenerator
        self.soundtrackGenerator = soundtrackGenerator
        self.audioMixer = audioMixer
        self.exporter = exporter
    }

    // MARK: - Project lifecycle

    func loadSampleProject() async {
        isProcessing = true
        statusMessage = "Loading project..."
        defer { isProcessing = false; statusMessage = nil }

        do {
            let projects = try await repository.list()
            if let first = projects.first {
                project = first
            } else {
                project = try await repository.create(title: "The Shadow Protocol", author: "Catherine M. Vance")
            }
            refreshViewState()
        } catch {
            statusMessage = "Failed to load project: \(error.localizedDescription)"
        }
    }

    // MARK: - View state

    private func refreshViewState() {
        guard let project else { return }
        projectViewState = project.makeViewState()
        activeJobs = project.generationJobs.map { JobViewState(job: $0) }
        reviewIssues = project.reviewIssues
            .filter { !$0.isResolved }
            .map { ReviewIssueViewState(issue: $0) }
    }

    // MARK: - Navigation

    func navigateToStage(_ stage: WorkflowStage) {
        selectedStage = stage
    }

    func navigateToScene(_ sceneID: StudioDomain.Scene.ID, chapterID: Chapter.ID) {
        selectedChapterID = chapterID
        selectedSceneID = sceneID
    }

    func navigateToBlock(_ blockID: ScriptBlock.ID) {
        selectedBlockID = blockID
    }

    // MARK: - Stage operations

    func updateStageStatus(_ stage: WorkflowStage, status: WorkflowStageStatus) {
        project?.updateStage(stage, status: status)
        refreshViewState()
    }

    func stage(for stage: WorkflowStage) -> WorkflowStageInfo? {
        project?.stage(for: stage)
    }

    // MARK: - Project mutators

    func updateBlockSpeaker(_ blockID: ScriptBlock.ID, speakerID: Character.ID?) {
        guard let idx = project?.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        project?.blocks[idx].speakerID = speakerID
        if speakerID != nil {
            project?.blocks[idx].speakerConfidence = 1.0
            // Mark downstream stages as potentially stale
            project?.updateStage(.script, status: .needsReview)
        }
        refreshViewState()
    }

    func updateBlockType(_ blockID: ScriptBlock.ID, type: BlockType) {
        guard let idx = project?.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        project?.blocks[idx].type = type
        if type == .narration {
            project?.blocks[idx].speakerID = nil
        }
        refreshViewState()
    }

    func updateBlockText(_ blockID: ScriptBlock.ID, text: String) {
        guard let idx = project?.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        project?.blocks[idx].productionText = text
        refreshViewState()
    }

    func toggleBlockExcluded(_ blockID: ScriptBlock.ID) {
        guard let idx = project?.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        project?.blocks[idx].isExcluded.toggle()
        refreshViewState()
    }

    func resetBlockToSource(_ blockID: ScriptBlock.ID) {
        guard let idx = project?.blocks.firstIndex(where: { $0.id == blockID }) else { return }
        let sourceText = project?.blocks[idx].sourceText ?? ""
        project?.blocks[idx].productionText = sourceText
        refreshViewState()
    }

    func mergeBlocks(_ id1: ScriptBlock.ID, _ id2: ScriptBlock.ID) {
        // Simplified: just remove the second block
        project?.blocks.removeAll { $0.id == id2 }
        refreshViewState()
    }

    func splitBlock(_ blockID: ScriptBlock.ID, at position: Int) {
        // Simplified
        refreshViewState()
    }

    // MARK: - Character mutators

    func updateCharacterVoice(_ characterID: Character.ID, voiceProfileID: VoiceProfile.ID) {
        guard let idx = project?.characters.firstIndex(where: { $0.id == characterID }) else { return }
        project?.characters[idx].voiceProfileID = voiceProfileID
        refreshViewState()
    }

    func mergeCharacters(_ id1: Character.ID, _ id2: Character.ID) {
        // Simplified: keep id1, remove id2, update blocks
        guard project?.character(for: id2) != nil else { return }
        project?.blocks.indices.forEach { idx in
            if project?.blocks[idx].speakerID == id2 {
                project?.blocks[idx].speakerID = id1
            }
        }
        project?.characters.removeAll { $0.id == id2 }
        // Resolve duplicate character review issue
        project?.reviewIssues.indices.forEach { idx in
            if project?.reviewIssues[idx].type == .duplicateCharacter {
                project?.reviewIssues[idx].isResolved = true
            }
        }
        refreshViewState()
    }

    func setNarrator(_ characterID: Character.ID) {
        project?.narratorID = characterID
        guard let characters = project?.characters else { return }
        let narratorFlags = characters.map { $0.id == characterID }
        for idx in characters.indices {
            project?.characters[idx].isNarrator = narratorFlags[idx]
        }
        refreshViewState()
    }

    // MARK: - Generation

    func cancelJob(_ jobID: GenerationJob.ID) {
        guard let idx = project?.generationJobs.firstIndex(where: { $0.id == jobID }) else { return }
        project?.generationJobs[idx].status = .cancelled
        refreshViewState()
    }

    func retryJob(_ jobID: GenerationJob.ID) {
        guard let idx = project?.generationJobs.firstIndex(where: { $0.id == jobID }) else { return }
        project?.generationJobs[idx].status = .queued
        project?.generationJobs[idx].progress = 0
        project?.generationJobs[idx].errorMessage = nil
        refreshViewState()
    }

    // MARK: - Review

    func resolveIssue(_ issueID: ReviewIssue.ID) {
        guard let idx = project?.reviewIssues.firstIndex(where: { $0.id == issueID }) else { return }
        project?.reviewIssues[idx].isResolved = true
        refreshViewState()
    }

    func navigateToIssue(_ issue: ReviewIssueViewState) {
        selectedStage = issue.relatedStage
        // Parse the deep-link ID
        let parts = issue.relatedEntityID.split(separator: ":")
        if parts.count == 2 {
            let type = String(parts[0])
            let idString = String(parts[1])
            if let uuid = UUID(uuidString: idString) {
                switch type {
                case "character":
                    // Navigate to characters stage with this character
                    selectedStage = .characters
                    // We'd scroll to this character in a real implementation
                    break
                case "scene":
                    if let scene = project?.scenes.first(where: { $0.id.rawValue == uuid }) {
                        selectedSceneID = scene.id
                        selectedChapterID = scene.chapterID
                        selectedStage = .script
                    }
                    break
                case "block":
                    selectedBlockID = ScriptBlock.ID(from: idString) ?? selectedBlockID
                    selectedStage = .script
                    break
                default:
                    selectedStage = issue.relatedStage
                }
            }
        }
    }
}
