import Foundation

/// Records which model is assigned to which purpose in a project.
public struct ModelAssignment: Codable, Sendable, Identifiable {
    public let id: String  // purpose + model spec ID
    public var purpose: String
    public var repositoryID: String
    public var revision: String
    public var backend: String
    public var selectedFilename: String?
    public var generationParameters: [String: String]

    public init(
        id: String = "",
        purpose: String,
        repositoryID: String,
        revision: String,
        backend: String = "mlx",
        selectedFilename: String? = nil,
        generationParameters: [String: String] = [:]
    ) {
        self.id = id.isEmpty ? "\(purpose):\(repositoryID)@\(revision)" : id
        self.purpose = purpose
        self.repositoryID = repositoryID
        self.revision = revision
        self.backend = backend
        self.selectedFilename = selectedFilename
        self.generationParameters = generationParameters
    }
}
