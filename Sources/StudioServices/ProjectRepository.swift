import Foundation
import StudioDomain

/// Persistence protocol for projects.
public protocol ProjectRepository: Sendable {
    func create(title: String, author: String) async throws -> Project
    func load(_ id: Project.ID) async throws -> Project
    func save(_ project: Project) async throws
    func delete(_ id: Project.ID) async throws
    func list() async throws -> [Project]
}
