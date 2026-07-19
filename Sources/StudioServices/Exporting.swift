import Foundation
import StudioDomain

/// Export protocol for producing final audiobook files.
public protocol Exporting: Sendable {
    func validate(_ project: Project) async throws -> [ReviewIssue]
    func export(_ project: Project, config: ExportConfiguration, progress: @escaping @Sendable (Double) -> Void) async throws -> [URL]
    func cancel()
}
