import Testing
import Foundation
@testable import StudioDomain
@testable import StudioMocks

@Suite struct MockSampleDataTests {

    @Test func buildsProject() {
        let project = MockSampleData.buildProject()
        #expect(project.title == "The Shadow Protocol")
        #expect(project.author == "Catherine M. Vance")
        #expect(project.chapters.count == 3)
        #expect(project.scenes.count == 10)
        #expect(project.characters.count == 7)
    }

    @Test func projectHasNarrator() {
        let project = MockSampleData.buildProject()
        let narrators = project.characters.filter { $0.isNarrator }
        #expect(narrators.count == 1)
        #expect(narrators.first?.name == "Narrator")
    }

    @Test func voiceProfilesGenerated() {
        let project = MockSampleData.buildProject()
        #expect(project.voiceProfiles.count == 8)
        #expect(project.voiceProfiles.contains { $0.isNarratorVoice })
    }

    @Test func sampleHasAwkwardCases() {
        let project = MockSampleData.buildProject()

        // Unnamed character
        let unnamed = project.characters.first { $0.name == "Unnamed Guard" }
        #expect(unnamed != nil)

        // Alias
        let aliases = project.characters.filter { !$0.aliases.isEmpty }
        #expect(aliases.count >= 2) // Elena has aliases, plus guard has alias

        // Unresolved speaker
        let unresolved = project.blocks.filter { $0.needsSpeakerResolution }
        #expect(!unresolved.isEmpty)

        // Duplicate
        let duplicates = project.characters.filter { $0.notes.contains("DUPLICATE") }
        #expect(!duplicates.isEmpty)
    }

    @Test func sampleHasReviewIssues() {
        let project = MockSampleData.buildProject()
        #expect(project.reviewIssues.count > 5)
        #expect(project.reviewIssues.contains { $0.type == .duplicateCharacter })
        #expect(project.reviewIssues.contains { $0.type == .failedGeneration })
        #expect(project.reviewIssues.contains { $0.type == .staleDialogue })
    }

    @Test func sampleHasGenerationJobs() {
        let project = MockSampleData.buildProject()
        #expect(project.generationJobs.count == 5)
        #expect(project.generationJobs.contains { $0.status == .completed })
        #expect(project.generationJobs.contains { $0.status == .running })
        #expect(project.generationJobs.contains { $0.status == .failed })
        #expect(project.generationJobs.contains { $0.status == .queued })
    }

    @Test func workflowStagesAllPresent() {
        let project = MockSampleData.buildProject()
        #expect(project.workflowStages.count == 9)
        let importStage = project.stage(for: .import)
        #expect(importStage?.status == .complete)
    }
}

@Suite struct MockAudioGeneratorTests {

    @Test func generateToneProducesWAV() {
        let data = MockAudioGenerator.generateTone(frequency: 440, duration: 1.0)
        #expect(data.count > 44) // WAV header is 44 bytes
        // Check RIFF header
        let riffString = String(data: data.prefix(4), encoding: .ascii)
        #expect(riffString == "RIFF")
        let waveString = String(data: data.subdata(in: 8..<12), encoding: .ascii)
        #expect(waveString == "WAVE")
    }

    @Test func generateAmbientProducesWAV() {
        let data = MockAudioGenerator.generateAmbient(duration: 1.0)
        #expect(data.count > 44)
    }

    @Test func toneDurationMatches() {
        let duration: TimeInterval = 2.0
        let sampleRate = 24000
        let data = MockAudioGenerator.generateTone(frequency: 440, duration: duration, sampleRate: sampleRate)
        let expectedDataSize = Int(duration) * sampleRate * 2 // 16-bit mono
        #expect(data.count == 44 + expectedDataSize)
    }
}

@Suite struct MockProjectRepositoryTests {

    @Test @MainActor func loadReturnsSampleProject() async throws {
        let repo = MockProjectRepository()
        let project = try await repo.load(MockSampleData.projectID)
        #expect(project.title == "The Shadow Protocol")
    }

    @Test @MainActor func listReturnsProjects() async throws {
        let repo = MockProjectRepository()
        let projects = try await repo.list()
        #expect(!projects.isEmpty)
    }
}

@Suite struct MockEPUBImporterTests {

    @Test func importReturnsSampleData() async throws {
        let importer = MockEPUBImporter()
        var progressValues: [Double] = []
        let result = try await importer.importEPUB(
            from: URL(fileURLWithPath: "/test.epub"),
            progress: { progressValues.append($0) }
        )
        #expect(result.metadata.title == "The Shadow Protocol")
        #expect(result.metadata.author == "Catherine M. Vance")
        #expect(result.metadata.tableOfContents.count == 3)
        #expect(!progressValues.isEmpty)
        #expect(progressValues.last == 1.0)
    }
}

@Suite struct MockSpeechGeneratorTests {

    @Test func generateSpeechProducesAudio() async throws {
        let generator = MockSpeechGenerator()
        let voice = VoiceProfile(name: "Test", description: "Test voice", tone: "Warm")
        let result = try await generator.generateSpeech(
            text: "Hello, this is a test of the speech generator.",
            voiceProfile: voice,
            performanceDirection: nil,
            speakingRate: nil,
            seed: 42
        )
        #expect(!result.audioData.isEmpty)
        #expect(result.sampleRate == 24000)
        #expect(result.channelCount == 1)
        #expect(result.duration > 0)
    }
}

@Suite struct MockExporterTests {

    @Test func validateReturnsIssues() async throws {
        let exporter = MockExporter()
        let project = MockSampleData.buildProject()
        let issues = try await exporter.validate(project)
        // Export validation should find issues in the sample project
        #expect(!issues.isEmpty)
    }
}
