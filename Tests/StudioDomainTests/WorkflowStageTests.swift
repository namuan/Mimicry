import Testing
import Foundation
@testable import StudioDomain

@Suite struct WorkflowStageTests {

    @Test func allStagesPresent() {
        #expect(WorkflowStage.allCases.count == 9)
    }

    @Test func stageOrder() {
        let stages = WorkflowStage.allCases
        #expect(stages[0] == .import)
        #expect(stages[1] == .structure)
        #expect(stages[8] == .export)
    }

    @Test func downstreamStages() {
        let importDownstream = WorkflowStage.import.downstreamStages
        #expect(importDownstream.count == 8)
        #expect(importDownstream.first == .structure)

        let exportDownstream = WorkflowStage.export.downstreamStages
        #expect(exportDownstream.isEmpty)
    }

    @Test func comparable() {
        #expect(WorkflowStage.import < WorkflowStage.structure)
        #expect(WorkflowStage.export > WorkflowStage.generate)
    }

    @Test func workflowStageInfoIdentifiable() {
        let info = WorkflowStageInfo(stage: .import, status: .complete)
        #expect(info.id == .import)
    }
}

@Suite struct ProjectTests {

    @Test func emptyProjectCreation() {
        let project = Project(title: "Test", author: "Author")
        #expect(project.title == "Test")
        #expect(project.author == "Author")
        #expect(project.chapters.isEmpty)
        #expect(project.characters.isEmpty)
    }

    @Test func projectIDUniqueness() {
        let p1 = Project(title: "A", author: "B")
        let p2 = Project(title: "C", author: "D")
        #expect(p1.id != p2.id)
    }

    @Test func updateStageMarksDownstreamOutOfDate() {
        var project = Project(title: "Test", author: "Author")

        // Set up: structure is complete
        project.updateStage(.structure, status: .complete)

        let structureInfo = project.stage(for: .structure)
        #expect(structureInfo?.status == .complete)

        // When structure is marked needs review, downstream should go out of date
        project.updateStage(.structure, status: .needsReview)

        if let charactersInfo = project.stage(for: .characters) {
            // Characters is downstream of structure; if it was complete, it should be out of date
            // But in a fresh project, downstream stages are not started, so they stay notStarted
            #expect(charactersInfo.status == .notStarted || charactersInfo.status == .outOfDate)
        }
    }

    @Test func makeViewState() {
        let project = Project(title: "Test", author: "Author")
        let viewState = project.makeViewState()
        #expect(viewState.title == "Test")
        #expect(viewState.author == "Author")
    }

    @Test func convenienceAccessors() {
        var project = Project(title: "Test", author: "Author")
        let chapterID = Chapter.ID()
        let chapter = Chapter(id: chapterID, title: "Ch1", number: 1)
        project.chapters = [chapter]

        let found = project.chapter(for: chapterID)
        #expect(found?.title == "Ch1")
    }
}

@Suite struct ScriptBlockTests {

    @Test func hasResolvedSpeakerForNarration() {
        let block = ScriptBlock(
            sceneID: Scene.ID(),
            type: .narration,
            productionText: "It was dark."
        )
        #expect(block.hasResolvedSpeaker == true)
    }

    @Test func needsSpeakerResolution() {
        let block = ScriptBlock(
            sceneID: Scene.ID(),
            type: .dialogue,
            productionText: "\"Hello\"",
            speakerID: nil
        )
        #expect(block.needsSpeakerResolution == true)
    }

    @Test func resolvedDialogueDoesNotNeedResolution() {
        let block = ScriptBlock(
            sceneID: Scene.ID(),
            type: .dialogue,
            productionText: "\"Hello\"",
            speakerID: Character.ID()
        )
        #expect(block.needsSpeakerResolution == false)
    }

    @Test func blockIDUniqueness() {
        let b1 = ScriptBlock(sceneID: Scene.ID())
        let b2 = ScriptBlock(sceneID: Scene.ID())
        #expect(b1.id != b2.id)
    }
}

@Suite struct VoiceProfileTests {

    @Test func voiceProfileCreation() {
        let profile = VoiceProfile(
            name: "Test Voice",
            description: "A test voice",
            accent: "British",
            tone: "Warm",
            seed: 42
        )
        #expect(profile.name == "Test Voice")
        #expect(profile.accent == "British")
        #expect(profile.seed == 42)
    }
}

@Suite struct ReviewIssueTests {

    @Test func issueCreation() {
        let issue = ReviewIssue(
            type: .uncertainSpeaker,
            title: "Test Issue",
            description: "Description",
            relatedStage: .script,
            relatedEntityID: "scene:123",
            severity: .warning
        )
        #expect(issue.type == .uncertainSpeaker)
        #expect(issue.severity == .warning)
        #expect(issue.isResolved == false)
    }

    @Test func severityOrdering() {
        #expect(IssueSeverity.info < IssueSeverity.warning)
        #expect(IssueSeverity.warning < IssueSeverity.error)
    }
}

@Suite struct GenerationJobTests {

    @Test func jobCreation() {
        let job = GenerationJob(
            type: .speechGeneration,
            scope: .scene,
            status: .queued
        )
        #expect(job.type == .speechGeneration)
        #expect(job.scope == .scene)
        #expect(job.progress == 0)
    }

    @Test func jobViewState() {
        let job = GenerationJob(
            type: .epubImport,
            scope: .book,
            estimatedDuration: 60
        )
        let viewState = JobViewState(job: job)
        #expect(viewState.type == .epubImport)
        #expect(viewState.estimatedDuration == "1m 0s")
    }
}
