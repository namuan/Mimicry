import Foundation
import StudioDomain
import StudioServices

/// Mock exporter that validates the project and simulates file export.
public final class MockExporter: Exporting, @unchecked Sendable {
    private nonisolated(unsafe) var isCancelled = false

    public init() {}

    public func validate(_ project: Project) async throws -> [ReviewIssue] {
        try await Task.sleep(for: .milliseconds(500))
        return project.reviewIssues.filter { $0.relatedStage == .export || $0.severity == .error }
    }

    public func export(
        _ project: Project,
        config: ExportConfiguration,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> [URL] {
        isCancelled = false

        let chapterCount = project.chapters.count
        var outputURLs: [URL] = []

        for (index, chapter) in project.chapters.enumerated() {
            let cancelled = isCancelled
            if cancelled { throw CancellationError() }

            let stepProgress = Double(index + 1) / Double(chapterCount)
            progress(stepProgress)

            // Simulate export time per chapter
            try await Task.sleep(for: .seconds(1.0))

            // Build mock chapter audio
            let chapterAudio = MockAudioGenerator.generateTone(
                frequency: 220 + Double(index) * 30,
                duration: 30.0
            )

            // Simulate writing to temp directory
            let tempDir = FileManager.default.temporaryDirectory
            let filename = config.chapterNamingTemplate
                .replacingOccurrences(of: "{number}", with: "\(chapter.number)")
                .replacingOccurrences(of: "{title}", with: chapter.title)
                .appending(".\(config.format.rawValue.lowercased())")
            let outputURL = tempDir.appendingPathComponent(filename)

            // In a real implementation, we'd write the file
            _ = chapterAudio

            outputURLs.append(outputURL)
        }

        progress(1.0)
        return outputURLs
    }

    public func cancel() {
        isCancelled = true
    }
}
