import Foundation
import StudioDomain
import StudioServices

/// Mock EPUB importer that returns pre-built sample data with simulated progress.
public final class MockEPUBImporter: EPUBImporting, @unchecked Sendable {
    public init() {}

    public func importEPUB(
        from url: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> (chapters: [Chapter], scenes: [Scene], blocks: [ScriptBlock], metadata: EPUBMetadata) {
        // Simulate import progress
        let steps = ["Parsing EPUB structure...", "Extracting text content...", "Detecting chapters...", "Processing metadata..."]
        for (i, _) in steps.enumerated() {
            try await Task.sleep(for: .milliseconds(600))
            progress(Double(i + 1) / Double(steps.count))
        }

        let metadata = EPUBMetadata(
            title: "The Shadow Protocol",
            author: "Catherine M. Vance",
            tableOfContents: [
                TOCEntry(id: "toc1", title: "Chapter 1: The Package"),
                TOCEntry(id: "toc2", title: "Chapter 2: Safe House"),
                TOCEntry(id: "toc3", title: "Chapter 3: The Exchange"),
            ]
        )

        let project = MockSampleData.buildProject()
        return (project.chapters, project.scenes, project.blocks, metadata)
    }
}
