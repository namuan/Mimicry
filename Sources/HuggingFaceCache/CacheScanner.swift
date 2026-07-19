import Foundation
import ModelRegistry

/// Structured info about a discovered repository in the cache.
public struct DiscoveredRepository: Sendable {
    /// The repository ID inferred from the directory name (e.g. "unsloth/Qwen3.5-0.8B-GGUF")
    public let repositoryID: String
    /// The cache directory name (e.g. "models--unsloth--Qwen3.5-0.8B-GGUF")
    public let directoryName: String
    /// Available snapshot commit hashes.
    public let snapshots: [String]
    /// Files found in each snapshot (snapshot hash → file names).
    public let snapshotFiles: [String: [String]]
    /// Total size in bytes.
    public let totalSize: Int64

    /// Whether any bundled model specification matches this repository.
    public var matchesBundledModel: Bool {
        BundledModelCatalogue.allModels.contains { $0.repositoryID == repositoryID }
    }
}

/// Scans the local Hugging Face cache for available models.
public struct CacheScanner: Sendable {
    private let configuration: HuggingFaceCacheConfiguration
    private nonisolated(unsafe) let fileManager: FileManager

    public init(
        configuration: HuggingFaceCacheConfiguration = HuggingFaceCacheConfiguration(),
        fileManager: FileManager = .default
    ) {
        self.configuration = configuration
        self.fileManager = fileManager
    }

    /// Check the status of a specific model specification in the cache.
    public func inspect(_ specification: HuggingFaceModelSpecification) async -> CachedModelStatus {
        let repoDir = CacheLayout.repositoryDirectory(
            in: configuration.hubCacheDirectory,
            repositoryID: specification.repositoryID
        )

        guard fileManager.fileExists(atPath: repoDir.path) else {
            return .missing
        }

        // Resolve the revision
        let snapshotsDir = CacheLayout.snapshotsDirectory(in: repoDir)

        // Try exact commit hash first
        let commit: String
        if fileManager.fileExists(atPath: CacheLayout.snapshotDirectory(in: repoDir, commit: specification.revision).path) {
            commit = specification.revision
        } else if let prefixMatch = findSnapshotWithPrefix(specification.revision, in: snapshotsDir) {
            // Partial hash match (e.g. first 12 chars matching a 40-char commit hash)
            commit = prefixMatch
        } else if let resolved = CacheLayout.resolveRef(in: repoDir, ref: specification.revision) {
            commit = resolved
        } else {
            return .missing
        }

        let snapshotDir = CacheLayout.snapshotDirectory(in: repoDir, commit: commit)

        guard fileManager.fileExists(atPath: snapshotDir.path) else {
            return .missing
        }

        // Validate files
        let requiredPaths = specification.requiredFiles.map { $0.path }
        let (present, missing) = CacheLayout.validateSnapshot(
            at: snapshotDir,
            requiredFiles: requiredPaths
        )

        // Resolve symlinks and verify at least one model file has actual content.
        // HF cache snapshots contain symlinks to blobs — must follow symlinks to
        // get real file sizes (lstat gives symlink path length, not blob size).
        var hasRealContent = false
        var totalResolvedBytes: Int64 = 0
        for file in present {
            let resolvedURL = file.resolvingSymlinksInPath()
            guard fileManager.fileExists(atPath: resolvedURL.path),
                  let attrs = try? fileManager.attributesOfItem(atPath: resolvedURL.path),
                  let size = attrs[.size] as? Int64,
                  size > 0
            else { continue }
            totalResolvedBytes += size
            let ext = file.pathExtension.lowercased()
            if ext == "gguf" || ext == "safetensors" {
                hasRealContent = true
            }
        }

        if missing.isEmpty {
            if !hasRealContent {
                return .corrupt(message: "Model files not downloaded — snapshot contains only metadata symlinks. Use Download to fetch the model weights.")
            }
            return .cached(snapshotDirectory: snapshotDir)
        } else if !present.isEmpty {
            return .partiallyCached(present: present, missing: specification.requiredFiles.filter { missing.contains($0.path) })
        } else {
            return .missing
        }
    }

    /// Calculate total disk usage of the cache.
    public func calculateDiskUsage() -> Int64 {
        var totalSize: Int64 = 0
        let hubDir = configuration.hubCacheDirectory

        guard let enumerator = fileManager.enumerator(
            at: hubDir,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            totalSize += Int64(fileSize)
        }

        return totalSize
    }

    /// Discover all model repositories in the cache.
    public func discoverRepositories() -> [String] {
        let hubDir = configuration.hubCacheDirectory
        guard let contents = try? fileManager.contentsOfDirectory(atPath: hubDir.path) else {
            return []
        }
        return contents.filter { $0.hasPrefix("models--") }
    }

    /// Discover detailed information about all repositories in the cache.
    public func discoverRepositoryDetails() -> [DiscoveredRepository] {
        let dirNames = discoverRepositories()
        let hubDir = configuration.hubCacheDirectory

        return dirNames.compactMap { dirName in
            let repoDir = hubDir.appendingPathComponent(dirName)
            let snapshotsDir = CacheLayout.snapshotsDirectory(in: repoDir)

            // Get snapshot hashes
            let snapshotHashes: [String]
            if let contents = try? fileManager.contentsOfDirectory(atPath: snapshotsDir.path) {
                snapshotHashes = contents
            } else {
                snapshotHashes = []
            }

            // Get files per snapshot
            var snapshotFiles: [String: [String]] = [:]
            var totalSize: Int64 = 0

            for hash in snapshotHashes {
                let snapshotDir = snapshotsDir.appendingPathComponent(hash)
                if let files = try? fileManager.contentsOfDirectory(atPath: snapshotDir.path) {
                    snapshotFiles[hash] = files.sorted()

                    // Calculate size of files in this snapshot (skip broken symlinks)
                    for file in files {
                        let fileURL = snapshotDir.appendingPathComponent(file)
                        // Resolve symlinks and check the actual file exists
                        let resolvedURL = fileURL.resolvingSymlinksInPath()
                        if fileManager.fileExists(atPath: resolvedURL.path),
                           let attrs = try? fileManager.attributesOfItem(atPath: resolvedURL.path),
                           let size = attrs[.size] as? Int64,
                           size > 0 {
                            totalSize += size
                        }
                    }
                }
            }

            // Infer repository ID from directory name
            // "models--unsloth--Qwen3.5-0.8B-GGUF" → "unsloth/Qwen3.5-0.8B-GGUF"
            let repoID = repositoryID(from: dirName)

            return DiscoveredRepository(
                repositoryID: repoID,
                directoryName: dirName,
                snapshots: snapshotHashes.sorted(),
                snapshotFiles: snapshotFiles,
                totalSize: totalSize
            )
        }
    }

    /// Convert a cache directory name to a repository ID.
    /// "models--unsloth--Qwen3.5-0.8B-GGUF" → "unsloth/Qwen3.5-0.8B-GGUF"
    public func repositoryID(from directoryName: String) -> String {
        let stripped = directoryName.hasPrefix("models--")
            ? String(directoryName.dropFirst("models--".count))
            : directoryName
        // Split on "--" but only the first occurrence (publisher/repo-name)
        if let firstDashIndex = stripped.firstIndex(of: "-"),
           stripped[stripped.index(after: firstDashIndex)] == "-" {
            // Found the first "--"
            let publisher = String(stripped[..<firstDashIndex])
            let repo = String(stripped[stripped.index(firstDashIndex, offsetBy: 2)...])
            return "\(publisher)/\(repo)"
        }
        return stripped
    }

    /// Find a snapshot directory whose name starts with the given prefix.
    private func findSnapshotWithPrefix(_ prefix: String, in snapshotsDir: URL) -> String? {
        guard let contents = try? fileManager.contentsOfDirectory(atPath: snapshotsDir.path) else {
            return nil
        }
        return contents.first { $0.hasPrefix(prefix) }
    }

    /// Discover snapshots for a repository.
    public func discoverSnapshots(repositoryID: String) -> [String] {
        let repoDir = CacheLayout.repositoryDirectory(
            in: configuration.hubCacheDirectory,
            repositoryID: repositoryID
        )
        let snapshotsDir = CacheLayout.snapshotsDirectory(in: repoDir)
        guard let contents = try? fileManager.contentsOfDirectory(atPath: snapshotsDir.path) else {
            return []
        }
        return contents
    }
}
