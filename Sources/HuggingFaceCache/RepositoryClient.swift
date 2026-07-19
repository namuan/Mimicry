import Foundation
import ModelRegistry

/// Protocol for interacting with Hugging Face repositories.
public protocol HuggingFaceRepositoryServing: Sendable {
    /// Inspect the local cache status for a model specification.
    func inspect(_ specification: HuggingFaceModelSpecification) async throws -> CachedModelStatus

    /// Download a model from Hugging Face into the local cache.
    func download(
        _ specification: HuggingFaceModelSpecification,
        progress: @escaping @Sendable (ModelDownloadProgress) -> Void
    ) async throws -> ResolvedModel
}

/// A stub/mock implementation of HuggingFaceRepositoryServing for development.
public actor MockRepositoryClient: HuggingFaceRepositoryServing {
    private let scanner: CacheScanner

    public init(configuration: HuggingFaceCacheConfiguration = HuggingFaceCacheConfiguration()) {
        self.scanner = CacheScanner(configuration: configuration)
    }

    public func inspect(_ specification: HuggingFaceModelSpecification) async throws -> CachedModelStatus {
        await scanner.inspect(specification)
    }

    public func download(
        _ specification: HuggingFaceModelSpecification,
        progress: @escaping @Sendable (ModelDownloadProgress) -> Void
    ) async throws -> ResolvedModel {
        let totalFiles = specification.requiredFiles.count
        // Simulate download progress
        for i in 0..<totalFiles {
            let fileSize = specification.requiredFiles[i].expectedSize ?? 100_000_000
            for step in 0...10 {
                let downloaded = Int64(Double(fileSize) * Double(step) / 10.0)
                progress(ModelDownloadProgress(
                    bytesDownloaded: downloaded,
                    totalBytes: fileSize,
                    filesCompleted: i,
                    totalFiles: totalFiles
                ))
                try await Task.sleep(for: .milliseconds(100))
            }
        }

        // Simulate a resolved model
        let cacheConfig = HuggingFaceCacheConfiguration()
        let repoDir = CacheLayout.repositoryDirectory(
            in: cacheConfig.hubCacheDirectory,
            repositoryID: specification.repositoryID
        )
        let snapshotDir = CacheLayout.snapshotDirectory(in: repoDir, commit: specification.revision)

        return ResolvedModel(
            specification: specification,
            snapshotDirectory: snapshotDir,
            modelFiles: specification.requiredFiles.map { snapshotDir.appendingPathComponent($0.path) },
            resolvedCommit: specification.revision,
            wasAlreadyCached: false
        )
    }
}
