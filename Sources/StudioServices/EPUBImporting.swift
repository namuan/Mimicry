import Foundation
import StudioDomain

/// EPUB parsing and import protocol.
public protocol EPUBImporting: Sendable {
    func importEPUB(from url: URL, progress: @escaping @Sendable (Double) -> Void) async throws -> (chapters: [Chapter], scenes: [Scene], blocks: [ScriptBlock], metadata: EPUBMetadata)
}

public struct EPUBMetadata: Codable, Sendable {
    public var title: String
    public var author: String
    public var coverImageData: Data?
    public var tableOfContents: [TOCEntry]

    public init(
        title: String = "",
        author: String = "",
        coverImageData: Data? = nil,
        tableOfContents: [TOCEntry] = []
    ) {
        self.title = title
        self.author = author
        self.coverImageData = coverImageData
        self.tableOfContents = tableOfContents
    }
}

public struct TOCEntry: Codable, Identifiable, Sendable {
    public let id: String
    public var title: String
    public var level: Int

    public init(id: String = UUID().uuidString, title: String, level: Int = 0) {
        self.id = id
        self.title = title
        self.level = level
    }
}
