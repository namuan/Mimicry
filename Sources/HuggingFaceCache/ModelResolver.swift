import Foundation
import ModelRegistry

/// Central actor for resolving models from the Hugging Face cache and downloading as needed.
public actor ModelResolver {
    private let configuration: HuggingFaceCacheConfiguration
    private let repositoryClient: any HuggingFaceRepositoryServing
    private let scanner: CacheScanner

    public init(
        configuration: HuggingFaceCacheConfiguration = HuggingFaceCacheConfiguration(),
        repositoryClient: any HuggingFaceRepositoryServing
    ) {
        self.configuration = configuration
        self.repositoryClient = repositoryClient
        self.scanner = CacheScanner(configuration: configuration)
    }

    /// Resolve a model: check cache, download if needed.
    public func resolve(
        _ specification: HuggingFaceModelSpecification,
        policy: ModelAccessPolicy
    ) async throws -> ResolvedModel {
        // 1. Check cache
        let status = await scanner.inspect(specification)

        switch status {
        case .cached(let snapshotDirectory):
            return ResolvedModel(
                specification: specification,
                snapshotDirectory: snapshotDirectory,
                modelFiles: specification.requiredFiles.map { snapshotDirectory.appendingPathComponent($0.path) },
                resolvedCommit: specification.revision,
                wasAlreadyCached: true
            )

        case .partiallyCached(_, let missing):
            if policy == .cacheOnly {
                throw ModelResolverError.modelUnavailableOffline(
                    repository: specification.repositoryID,
                    revision: specification.revision,
                    missingFiles: missing.map { $0.path }
                )
            }
            // Fall through to download

        case .missing:
            if policy == .cacheOnly {
                throw ModelResolverError.modelUnavailableOffline(
                    repository: specification.repositoryID,
                    revision: specification.revision,
                    missingFiles: specification.requiredFiles.map { $0.path }
                )
            }
            // Fall through to download

        case .gated:
            throw ModelResolverError.authenticationRequired(repository: specification.repositoryID)

        case .incompatible(let reason):
            throw ModelResolverError.incompatibleModel(reason: reason)

        case .corrupt(let message):
            throw ModelResolverError.corruptModel(message: message)
        }

        // 2. Download
        return try await repositoryClient.download(specification) { progress in
            // Progress can be published to UI
            Task { @MainActor in
                // In production: update UI progress
            }
        }
    }

    /// Get the current cache configuration.
    public func getConfiguration() -> HuggingFaceCacheConfiguration {
        configuration
    }

    /// Get disk usage summary.
    public func getDiskUsage() -> Int64 {
        scanner.calculateDiskUsage()
    }

    /// Discover available repositories.
    public func discoverRepositories() -> [String] {
        scanner.discoverRepositories()
    }
}

/// Errors thrown during model resolution.
public enum ModelResolverError: Error, LocalizedError {
    case modelUnavailableOffline(repository: String, revision: String, missingFiles: [String])
    case authenticationRequired(repository: String)
    case incompatibleModel(reason: String)
    case corruptModel(message: String)
    case downloadFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .modelUnavailableOffline(let repo, let rev, let files):
            "Model unavailable offline\nRepository: \(repo)\nRevision: \(rev)\nMissing: \(files.joined(separator: ", "))"
        case .authenticationRequired(let repo):
            "Authentication required for gated repository: \(repo)"
        case .incompatibleModel(let reason):
            "Incompatible model: \(reason)"
        case .corruptModel(let msg):
            "Corrupted model: \(msg)"
        case .downloadFailed(let error):
            "Download failed: \(error.localizedDescription)"
        }
    }
}
