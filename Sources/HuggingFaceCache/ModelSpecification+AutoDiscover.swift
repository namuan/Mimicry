import Foundation
import ModelRegistry

extension HuggingFaceModelSpecification {
    /// Auto-discover a model specification from a cached repository.
    /// Infers backend from file types, purpose from naming heuristics,
    /// and memory from the total cached file size.
    public static func from(discovered: DiscoveredRepository) -> HuggingFaceModelSpecification? {
        // We need at least one snapshot with files
        guard let firstHash = discovered.snapshots.first,
              let files = discovered.snapshotFiles[firstHash],
              !files.isEmpty
        else { return nil }

        // Skip repos with no actual content (metadata-only, files not downloaded)
        guard discovered.totalSize > 1024 * 1024 else {
            return nil
        }

        // Infer backend from file extensions
        let hasGGUF = files.contains { $0.lowercased().hasSuffix(".gguf") }
        _ = files.contains { $0.lowercased().hasSuffix(".safetensors") }
        let backend: InferenceBackend = hasGGUF ? .llamaCpp : .mlx

        // Infer purpose
        let purpose = ModelPurpose.infer(from: discovered.repositoryID, files: files)

        // Build display name
        let shortName = discovered.repositoryID.split(separator: "/").last.map(String.init) ?? discovered.repositoryID
        let displayName = "\(shortName) (\(backend.rawValue))"

        // Estimate memory from file sizes
        let estimatedMemory: Int64? = if discovered.totalSize > 0 {
            switch backend {
            case .llamaCpp: discovered.totalSize
            case .mlx: Int64(Double(discovered.totalSize) * 1.3)
            }
        } else { nil }

        // Build required files from first snapshot
        let requiredFiles: [RequiredModelFile] = files.map { fileName in
            RequiredModelFile(path: fileName, expectedSize: nil, checksum: nil)
        }

        // Use first snapshot hash as revision
        let revision = firstHash

        // Build unique ID from repo + backend
        let id = "auto-\(discovered.repositoryID.replacingOccurrences(of: "/", with: "-"))-\(backend.rawValue)"

        return HuggingFaceModelSpecification(
            id: id,
            displayName: displayName,
            purpose: purpose,
            backend: backend,
            repositoryID: discovered.repositoryID,
            revision: revision,
            requiredFiles: requiredFiles,
            contextLength: nil,
            estimatedMemoryBytes: estimatedMemory,
            minimumMemoryBytes: estimatedMemory,
            licenseIdentifier: nil,
            gated: false
        )
    }
}
