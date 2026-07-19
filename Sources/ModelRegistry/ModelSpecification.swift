import Foundation

/// A required file within a model repository.
public struct RequiredModelFile: Codable, Sendable, Hashable {
    /// Relative path within the repository.
    public let path: String
    /// Expected file size in bytes, if known.
    public let expectedSize: Int64?
    /// SHA-256 checksum, if available.
    public let checksum: String?

    public init(path: String, expectedSize: Int64? = nil, checksum: String? = nil) {
        self.path = path
        self.expectedSize = expectedSize
        self.checksum = checksum
    }
}

/// Identifies a specific model by repository, revision, backend, and required files.
public struct ModelIdentity: Hashable, Codable, Sendable {
    public let repositoryID: String
    public let revision: String
    public let backend: InferenceBackend
    public let requiredFiles: [RequiredModelFile]

    public init(
        repositoryID: String,
        revision: String,
        backend: InferenceBackend,
        requiredFiles: [RequiredModelFile]
    ) {
        self.repositoryID = repositoryID
        self.revision = revision
        self.backend = backend
        self.requiredFiles = requiredFiles
    }

    /// Short display string for the UI.
    public var displayName: String {
        let shortRepo = repositoryID.split(separator: "/").last ?? Substring(repositoryID)
        let shortRev = String(revision.prefix(7))
        return "\(shortRepo)@\(shortRev) [\(backend.rawValue)]"
    }
}

/// Full specification of a model in the Hugging Face ecosystem.
public struct HuggingFaceModelSpecification: Codable, Identifiable, Sendable, Hashable {
    public let id: String
    public let displayName: String
    public let purpose: ModelPurpose
    public let backend: InferenceBackend
    public let repositoryID: String
    public let revision: String
    public let requiredFiles: [RequiredModelFile]
    public let contextLength: Int?
    public let estimatedMemoryBytes: Int64?
    public let minimumMemoryBytes: Int64?
    public let licenseIdentifier: String?
    public let gated: Bool

    public init(
        id: String,
        displayName: String,
        purpose: ModelPurpose,
        backend: InferenceBackend,
        repositoryID: String,
        revision: String,
        requiredFiles: [RequiredModelFile] = [],
        contextLength: Int? = nil,
        estimatedMemoryBytes: Int64? = nil,
        minimumMemoryBytes: Int64? = nil,
        licenseIdentifier: String? = nil,
        gated: Bool = false
    ) {
        self.id = id
        self.displayName = displayName
        self.purpose = purpose
        self.backend = backend
        self.repositoryID = repositoryID
        self.revision = revision
        self.requiredFiles = requiredFiles
        self.contextLength = contextLength
        self.estimatedMemoryBytes = estimatedMemoryBytes
        self.minimumMemoryBytes = minimumMemoryBytes
        self.licenseIdentifier = licenseIdentifier
        self.gated = gated
    }

    /// Build a ModelIdentity from this specification.
    public var identity: ModelIdentity {
        ModelIdentity(
            repositoryID: repositoryID,
            revision: revision,
            backend: backend,
            requiredFiles: requiredFiles
        )
    }
}

/// The result of resolving a model in the local cache.
public struct ResolvedModel: Sendable {
    public let specification: HuggingFaceModelSpecification
    public let snapshotDirectory: URL
    public let modelFiles: [URL]
    public let resolvedCommit: String
    public let wasAlreadyCached: Bool

    public init(
        specification: HuggingFaceModelSpecification,
        snapshotDirectory: URL,
        modelFiles: [URL],
        resolvedCommit: String,
        wasAlreadyCached: Bool
    ) {
        self.specification = specification
        self.snapshotDirectory = snapshotDirectory
        self.modelFiles = modelFiles
        self.resolvedCommit = resolvedCommit
        self.wasAlreadyCached = wasAlreadyCached
    }
}

/// Whether the app is allowed to download models.
public enum ModelAccessPolicy: Sendable {
    case online
    case cacheOnly
}

/// The status of a model in the local cache.
public enum CachedModelStatus: Sendable {
    case cached(snapshotDirectory: URL)
    case partiallyCached(present: [URL], missing: [RequiredModelFile])
    case missing
    case incompatible(reason: String)
    case gated(requiresAuth: Bool)
    case corrupt(message: String)
}

/// Progress information during model download.
public struct ModelDownloadProgress: Sendable {
    public let bytesDownloaded: Int64
    public let totalBytes: Int64
    public let filesCompleted: Int
    public let totalFiles: Int

    public var fractionComplete: Double {
        totalBytes > 0 ? Double(bytesDownloaded) / Double(totalBytes) : 0
    }

    public init(
        bytesDownloaded: Int64 = 0,
        totalBytes: Int64 = 0,
        filesCompleted: Int = 0,
        totalFiles: Int = 0
    ) {
        self.bytesDownloaded = bytesDownloaded
        self.totalBytes = totalBytes
        self.filesCompleted = filesCompleted
        self.totalFiles = totalFiles
    }
}
