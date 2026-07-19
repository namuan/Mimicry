import Foundation
import ModelRegistry

/// Resolves the Hugging Face cache location according to standard environment variable precedence.
public struct HuggingFaceCacheConfiguration: Sendable {
    /// The resolved cache home directory (HF_HOME or default).
    public let homeDirectory: URL
    /// The resolved hub cache directory (HF_HUB_CACHE or HF_HOME/hub or default).
    public let hubCacheDirectory: URL
    /// The source of the cache location (for displaying to users).
    public let source: CacheSource

    public enum CacheSource: String, Sendable {
        case environmentHFHubCache = "HF_HUB_CACHE environment variable"
        case environmentHFHome = "HF_HOME environment variable"
        case defaultLocation = "Default location"
    }

    /// Resolve the cache configuration from the current environment.
    public init() {
        let env = ProcessInfo.processInfo.environment

        if let hubCache = env["HF_HUB_CACHE"] {
            hubCacheDirectory = URL(fileURLWithPath: (hubCache as NSString).expandingTildeInPath)
            homeDirectory = env["HF_HOME"]
                .map { URL(fileURLWithPath: ($0 as NSString).expandingTildeInPath) }
                ?? URL(fileURLWithPath: "~/.cache/huggingface".expandingTildeInPath)
            source = .environmentHFHubCache
        } else if let hfHome = env["HF_HOME"] {
            homeDirectory = URL(fileURLWithPath: (hfHome as NSString).expandingTildeInPath)
            hubCacheDirectory = homeDirectory.appendingPathComponent("hub")
            source = .environmentHFHome
        } else {
            homeDirectory = URL(fileURLWithPath: "~/.cache/huggingface".expandingTildeInPath)
            hubCacheDirectory = homeDirectory.appendingPathComponent("hub")
            source = .defaultLocation
        }
    }

    /// Format bytes into human-readable string.
    public static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

private extension String {
    var expandingTildeInPath: String {
        (self as NSString).expandingTildeInPath
    }
}
