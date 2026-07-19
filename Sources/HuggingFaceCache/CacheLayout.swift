import Foundation

/// Understands the standard Hugging Face cache directory layout.
///
/// Layout:
/// ```
/// hub/
/// └── models--publisher--repository/
///     ├── blobs/
///     ├── refs/
///     └── snapshots/
///         └── <commit-hash>/
///             ├── config.json
///             ├── tokenizer.json
///             └── model files
/// ```
public struct CacheLayout: Sendable {
    /// Convert a repository ID to the directory name used in the cache.
    /// e.g., "mlx-community/Example-Model-4bit" → "models--mlx-community--Example-Model-4bit"
    public static func cacheDirectoryName(for repositoryID: String) -> String {
        let parts = repositoryID.split(separator: "/")
        if parts.count == 2 {
            return "models--\(parts[0])--\(parts[1])"
        }
        return "models--\(repositoryID.replacingOccurrences(of: "/", with: "--"))"
    }

    /// Path to the repository directory in the cache.
    public static func repositoryDirectory(
        in hubCacheDirectory: URL,
        repositoryID: String
    ) -> URL {
        hubCacheDirectory.appendingPathComponent(cacheDirectoryName(for: repositoryID))
    }

    /// Path to the refs directory.
    public static func refsDirectory(in repoDir: URL) -> URL {
        repoDir.appendingPathComponent("refs")
    }

    /// Path to the snapshots directory.
    public static func snapshotsDirectory(in repoDir: URL) -> URL {
        repoDir.appendingPathComponent("snapshots")
    }

    /// Path to a specific snapshot (commit hash).
    public static func snapshotDirectory(in repoDir: URL, commit: String) -> URL {
        snapshotsDirectory(in: repoDir).appendingPathComponent(commit)
    }

    /// Resolve a named reference (like "main") to a commit hash.
    public static func resolveRef(in repoDir: URL, ref: String) -> String? {
        let refFile = refsDirectory(in: repoDir).appendingPathComponent(ref)
        guard let content = try? String(contentsOf: refFile, encoding: .utf8) else {
            return nil
        }
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Check if a snapshot directory contains all required files.
    public static func validateSnapshot(
        at snapshotDir: URL,
        requiredFiles: [String]
    ) -> (present: [URL], missing: [String]) {
        var present: [URL] = []
        var missing: [String] = []

        for file in requiredFiles {
            let fileURL = snapshotDir.appendingPathComponent(file)
            if FileManager.default.fileExists(atPath: fileURL.path) {
                present.append(fileURL)
            } else {
                missing.append(file)
            }
        }

        return (present, missing)
    }
}
