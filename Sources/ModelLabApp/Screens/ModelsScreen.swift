import SwiftUI
import ModelRegistry
import HuggingFaceCache

struct ModelsScreen: View {
    @EnvironmentObject var labModel: ModelLabViewModel
    @State private var selectedUnrecognisedRepo: DiscoveredRepository?

    var body: some View {
        HSplitView {
            // Model list
            modelListPanel
                .frame(minWidth: 320)
                .padding()

            // Model detail
            modelDetailPanel
                .frame(minWidth: 400)
                .padding()
        }
    }

    // MARK: - Model List

    private var modelListPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Model Manager")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text(labModel.cacheStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            // Cache info
            VStack(alignment: .leading, spacing: 6) {
                cacheInfoRow("Cache", value: labModel.cacheStatus)
                cacheInfoRow("Disk Usage", value: labModel.diskUsage)
                cacheInfoRow("Installed", value: "\(labModel.installedModels.count) bundled model(s)")
                cacheInfoRow("Auto-discovered", value: "\(labModel.autoDiscoveredModels.count) model(s)")
                cacheInfoRow("Other repos", value: "\(labModel.unrecognisedRepositories.count) unrecognised")
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))

            // Group by purpose — with cache status
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(ModelPurpose.allCases, id: \.self) { purpose in
                        let models = BundledModelCatalogue.models(for: purpose)
                        if !models.isEmpty {
                            Text(purpose.rawValue)
                                .font(.headline)
                                .foregroundColor(.secondary)

                             ForEach(models) { model in
                                let isInstalled = labModel.installedModels.contains { $0.id == model.id }
                                    || labModel.autoDiscoveredModels.contains { $0.id == model.id }
                                modelRow(model, isInstalled: isInstalled)
                            }
                        }
                    }

                    // ── Auto-Discovered Models ──
                    if !labModel.autoDiscoveredModels.isEmpty {
                        Divider()
                            .padding(.vertical, 4)

                        Text("Auto-Discovered")
                            .font(.headline)
                            .foregroundColor(.green)

                        Text("Models detected in your cache and automatically configured.")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        // Group by inferred purpose
                        let purposes = Array(Set(labModel.autoDiscoveredModels.map { $0.purpose }))
                            .sorted { $0.rawValue < $1.rawValue }
                        ForEach(purposes, id: \.self) { purpose in
                            let purposeModels = labModel.autoDiscoveredModels.filter { $0.purpose == purpose }
                            if !purposeModels.isEmpty {
                                Text(purpose.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.green)

                                ForEach(purposeModels) { model in
                                    autoModelRow(model)
                                }
                            }
                        }
                    }

                    // ── Unrecognised Cached Repositories ──
                    if !labModel.unrecognisedRepositories.isEmpty {
                        Divider()
                            .padding(.vertical, 4)

                        Text("Unrecognised Cached Repositories")
                            .font(.headline)
                            .foregroundColor(.orange)

                        Text("These models exist in your Hugging Face cache but are not in the bundled catalogue.")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        ForEach(labModel.unrecognisedRepositories, id: \.repositoryID) { repo in
                            unrecognisedRepoRow(repo)
                        }
                    }
                }
            }

            HStack {
                Button("Refresh Cache") {
                    Task { await labModel.refreshCacheStatus() }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Spacer()
            }
        }
    }

    // MARK: - Bundled Model Row (with cache status)

    private func modelRow(_ model: HuggingFaceModelSpecification, isInstalled: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Cache status icon
                if isInstalled {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                } else {
                    Image(systemName: "arrow.down.circle")
                        .foregroundColor(.secondary.opacity(0.4))
                        .font(.caption)
                }

                Text(model.displayName)
                    .font(.body)
                    .fontWeight(model.id == labModel.selectedModel?.id ? .bold : .regular)
                Spacer()
                Text(model.backend.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
            }

            HStack {
                Text(model.repositoryID)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if let memory = model.estimatedMemoryBytes {
                    Text("· \(HuggingFaceCacheConfiguration.formatBytes(memory))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if model.gated {
                HStack {
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("Gated")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(model.id == labModel.selectedModel?.id
                    ? Color.accentColor.opacity(0.08)
                    : Color.secondary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isInstalled ? Color.green.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .onTapGesture {
            selectedUnrecognisedRepo = nil
            labModel.selectedModel = model
        }
    }

    // MARK: - Unrecognised Repo Row

    private func unrecognisedRepoRow(_ repo: DiscoveredRepository) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "shippingbox.fill")
                    .foregroundColor(.orange)
                    .font(.caption)

                Text(repo.repositoryID)
                    .font(.body)
                    .fontWeight(selectedUnrecognisedRepo?.repositoryID == repo.repositoryID ? .bold : .regular)
                    .lineLimit(1)

                Spacer()

                Text(HuggingFaceCacheConfiguration.formatBytes(repo.totalSize))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text("\(repo.snapshots.count) snapshot(s) · \(repo.directoryName)")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(selectedUnrecognisedRepo?.repositoryID == repo.repositoryID
                    ? Color.orange.opacity(0.08)
                    : Color.secondary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.4), lineWidth: 1.5)
        )
        .onTapGesture {
            labModel.selectedModel = nil
            selectedUnrecognisedRepo = repo
        }
    }

    // MARK: - Auto-Discovered Model Row

    private func autoModelRow(_ model: HuggingFaceModelSpecification) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)

                Text(model.displayName)
                    .font(.body)
                    .fontWeight(model.id == labModel.selectedModel?.id ? .bold : .regular)
                    .lineLimit(1)

                Spacer()

                Text(model.backend.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }

            HStack {
                Text(model.repositoryID)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if let memory = model.estimatedMemoryBytes {
                    Text("· \(HuggingFaceCacheConfiguration.formatBytes(memory))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if model.purpose == .unknown {
                HStack {
                    Image(systemName: "questionmark.diamond")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("Purpose could not be determined — review manually")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(model.id == labModel.selectedModel?.id
                    ? Color.green.opacity(0.08)
                    : Color.green.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.6), lineWidth: 1.5)
        )
        .onTapGesture {
            selectedUnrecognisedRepo = nil
            labModel.selectedModel = model
        }
    }

    private func cacheInfoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.caption)
                .lineLimit(2)
        }
    }

    // MARK: - Model Detail

    private var modelDetailPanel: some View {
        Group {
            if let model = labModel.selectedModel {
                bundledModelDetail(model)
            } else if let repo = selectedUnrecognisedRepo {
                unrecognisedRepoDetail(repo)
            } else {
                emptyDetail
            }
        }
    }

    // MARK: - Bundled Model Detail

    private func bundledModelDetail(_ model: HuggingFaceModelSpecification) -> some View {
        let isInstalled = labModel.installedModels.contains { $0.id == model.id }
            || labModel.autoDiscoveredModels.contains { $0.id == model.id }

        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    if isInstalled {
                        Label("Installed", systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                Spacer()
            }

            // Specifications
            VStack(alignment: .leading, spacing: 8) {
                detailRow("Purpose", model.purpose.rawValue)
                detailRow("Backend", model.backend.displayName)
                detailRow("Repository", model.repositoryID)
                detailRow("Revision", model.revision)
                detailRow("Status", isInstalled ? "Cached" : "Not installed")

                if let ctx = model.contextLength {
                    detailRow("Context Length", "\(ctx) tokens")
                }
                if let mem = model.estimatedMemoryBytes {
                    detailRow("Est. Memory", HuggingFaceCacheConfiguration.formatBytes(mem))
                }
                if let lic = model.licenseIdentifier {
                    detailRow("License", lic)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))

            // Required files
            if !model.requiredFiles.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Required Files")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    ForEach(model.requiredFiles, id: \.path) { file in
                        HStack {
                            Text(file.path)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            if let size = file.expectedSize {
                                Text(HuggingFaceCacheConfiguration.formatBytes(size))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }

            // Download progress
            if labModel.isDownloading {
                VStack(spacing: 6) {
                    ProgressView(value: labModel.downloadProgress)
                        .progressViewStyle(.linear)
                    Text("Downloading... \(Int(labModel.downloadProgress * 100))%")
                        .font(.caption)
                }
            }

            HStack {
                if isInstalled {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Model is cached")
                        .font(.body)
                        .foregroundColor(.green)
                } else {
                    Button("Download") {
                        Task { await labModel.downloadModel(model) }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(labModel.isDownloading)
                }

                if isInstalled {
                    Button("Delete") { }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .controlSize(.small)
                }

                Spacer()
            }
        }
    }

    // MARK: - Unrecognised Repo Detail

    private func unrecognisedRepoDetail(_ repo: DiscoveredRepository) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(repo.repositoryID)
                        .font(.title2)
                        .fontWeight(.bold)
                    Label("Unrecognised — not in bundled catalogue", systemImage: "questionmark.diamond")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 8) {
                detailRow("Directory", repo.directoryName)
                detailRow("Size", HuggingFaceCacheConfiguration.formatBytes(repo.totalSize))
                detailRow("Snapshots", "\(repo.snapshots.count)")
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))

            // Snapshots and files
            ForEach(repo.snapshots, id: \.self) { hash in
                VStack(alignment: .leading, spacing: 4) {
                    Text("Snapshot: \(String(hash.prefix(12)))...")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    if let files = repo.snapshotFiles[hash] {
                        ForEach(files, id: \.self) { file in
                            HStack {
                                Image(systemName: "doc")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(file)
                                    .font(.caption)
                                    .lineLimit(1)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.03)))
            }

            Divider()

            Text("Note")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("This repository was found in your Hugging Face cache but is not listed in Audiobook Studio's bundled model catalogue. It may have been downloaded by another tool (e.g., Hugging Face CLI, Python libraries, or another application).")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("To use this model, it must be added to the application's model registry or accessed through the LLM/Speech tabs with manual configuration.")
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
    }

    // MARK: - Empty Detail

    private var emptyDetail: some View {
        VStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("Select a model to view details")
                    .foregroundColor(.secondary)
                if labModel.installedModels.isEmpty && labModel.unrecognisedRepositories.isEmpty {
                    Text("No cached models found. Download a model or copy one into your Hugging Face cache.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            Spacer()
        }
    }

    private func detailRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.caption)
            Spacer()
        }
    }
}
