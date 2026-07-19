import Foundation
import StudioDomain
import StudioServices

/// Placeholder for SQLite persistence layer.
///
/// Spike 3 will implement:
/// - SQLiteProjectRepository conforming to ProjectRepository
/// - Schema migration
/// - Blob storage for audio (voice previews, generated speech, mixes)
/// - Project export/import
/// - Corruption detection and recovery
public enum StudioPersistenceStub {
    /// Stub to ensure the target compiles.
    public static let version = "0.1.0"
}
