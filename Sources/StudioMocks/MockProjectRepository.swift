import Foundation
import StudioDomain
import StudioServices

/// Mock project repository that works with a single in-memory sample project.
@MainActor
public final class MockProjectRepository: ProjectRepository {
    private var project: Project?

    public init() {}

    public func create(title: String, author: String) async throws -> Project {
        let p = Project(title: title, author: author)
        project = p
        return p
    }

    public func load(_ id: Project.ID) async throws -> Project {
        if let existing = project, existing.id == id {
            return existing
        }
        // On first load or ID mismatch, return the sample project
        let sample = MockSampleData.buildProject()
        project = sample
        return sample
    }

    public func save(_ project: Project) async throws {
        self.project = project
    }

    public func delete(_ id: Project.ID) async throws {
        project = nil
    }

    public func list() async throws -> [Project] {
        if let p = project {
            return [p]
        }
        let sample = MockSampleData.buildProject()
        project = sample
        return [sample]
    }
}
