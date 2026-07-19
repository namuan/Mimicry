import Foundation

/// Supported export formats.
public enum ExportFormat: String, Codable, Sendable, CaseIterable {
    case wav = "WAV"
    case mp3 = "MP3"
    case m4a = "M4A"
    case flac = "FLAC"
}

/// Export configuration for the final audiobook.
public struct ExportConfiguration: Codable, Sendable {
    public var format: ExportFormat
    public var outputDirectory: URL?
    public var chapterNamingTemplate: String
    public var includeCoverImage: Bool
    public var includeMetadata: Bool
    public var normalizeAudio: Bool
    public var targetLUFS: Double?

    public init(
        format: ExportFormat = .m4a,
        outputDirectory: URL? = nil,
        chapterNamingTemplate: String = "{number} - {title}",
        includeCoverImage: Bool = true,
        includeMetadata: Bool = true,
        normalizeAudio: Bool = true,
        targetLUFS: Double? = -16.0
    ) {
        self.format = format
        self.outputDirectory = outputDirectory
        self.chapterNamingTemplate = chapterNamingTemplate
        self.includeCoverImage = includeCoverImage
        self.includeMetadata = includeMetadata
        self.normalizeAudio = normalizeAudio
        self.targetLUFS = targetLUFS
    }
}
