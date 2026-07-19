import SwiftUI
import ModelRegistry
import HuggingFaceCache

struct DiagnosticsScreen: View {
    @EnvironmentObject var labModel: ModelLabViewModel

    var body: some View {
        VStack(spacing: 0) {
            Text("Diagnostics")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // System info
                    diagnosticSection("System") {
                        diagnosticRow("Hardware", ProcessInfo.processInfo.hostName)
                        diagnosticRow("macOS Version", ProcessInfo.processInfo.operatingSystemVersionString)
                        diagnosticRow("Physical Memory", HuggingFaceCacheConfiguration.formatBytes(Int64(ProcessInfo.processInfo.physicalMemory)))
                        diagnosticRow("Processor Count", "\(ProcessInfo.processInfo.processorCount)")
                        diagnosticRow("Active Processors", "\(ProcessInfo.processInfo.activeProcessorCount)")
                    }

                    // Cache diagnostics
                    diagnosticSection("Hugging Face Cache") {
                        let config = HuggingFaceCacheConfiguration()
                        diagnosticRow("Cache Directory", config.hubCacheDirectory.path)
                        diagnosticRow("Source", config.source.rawValue)
                        diagnosticRow("Disk Usage", labModel.diskUsage)
                        diagnosticRow("Repositories Found", "\(labModel.discoveredRepositories.count)")
                        diagnosticRow("HF_TOKEN Set", labModel.cacheStatus.contains("HF") ? "Yes" : "No")
                    }

                    // Known models
                    diagnosticSection("Known Models") {
                        ForEach(BundledModelCatalogue.allModels) { model in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.displayName)
                                    .font(.caption)
                                Text("\(model.repositoryID) [\(model.backend.rawValue)]")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    // Logs
                    diagnosticSection("Logs (\(labModel.logs.count))") {
                        ForEach(labModel.logs.suffix(20), id: \.self) { log in
                            Text(log)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                    }

                    // Performance notes
                    diagnosticSection("Notes") {
                        Text("• Model weights live in the Hugging Face cache, not in the app bundle or project database.")
                            .font(.caption)
                        Text("• Projects store model references (repository ID, revision, backend), never weights.")
                            .font(.caption)
                        Text("• The cache-only mode makes zero network requests.")
                            .font(.caption)
                        Text("• MLX and llama.cpp share the same Hugging Face cache via ModelResolver.")
                            .font(.caption)
                        Text("• Cancelled downloads never expose partial snapshots as ready.")
                            .font(.caption)
                    }
                }
                .padding()
            }
        }
    }

    private func diagnosticSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            VStack(alignment: .leading, spacing: 6) {
                content()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.secondary.opacity(0.05)))
        }
    }

    private func diagnosticRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 130, alignment: .leading)
            Text(value)
                .font(.caption)
                .lineLimit(3)
        }
    }
}
