import SwiftUI
import StudioDomain
import UniformTypeIdentifiers

private struct TOCEntry: Identifiable {
    let id: String
    let title: String
    var level: Int = 0
}

struct ImportScreen: View {
    let project: ProjectViewState
    @EnvironmentObject var model: StudioApplicationModel
    @State private var selectedFileURL: URL?
    @State private var importProgress: Double = 0
    @State private var isImporting = false
    @State private var tocEntries: [TOCEntry] = [
        TOCEntry(id: "toc1", title: "Chapter 1: The Package"),
        TOCEntry(id: "toc2", title: "Chapter 2: Safe House"),
        TOCEntry(id: "toc3", title: "Chapter 3: The Exchange"),
    ]
    @State private var excludedTOC: Set<String> = []

    var body: some View {
        HSplitView {
            // Left: EPUB source
            leftPanel
                .frame(minWidth: 300)
                .padding()

            // Right: Preview and metadata
            rightPanel
                .frame(minWidth: 400)
                .padding()
        }
    }

    // MARK: - Left Panel

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Import EPUB")
                .font(.title2)
                .fontWeight(.bold)

            // File selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Source File")
                    .font(.headline)
                    .foregroundColor(.secondary)

                HStack {
                    if let url = selectedFileURL {
                        VStack(alignment: .leading) {
                            Text(url.lastPathComponent)
                                .font(.body)
                                .lineLimit(1)
                            Text(url.deletingLastPathComponent().path)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button("Change") { selectedFileURL = nil }
                            .buttonStyle(.link)
                    } else {
                        Text("No file selected")
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Select EPUB...") {
                            selectEPUB()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }

            // Table of Contents
            if !tocEntries.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Table of Contents")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    List {
                        ForEach(tocEntries) { entry in
                            HStack {
                                Image(systemName: excludedTOC.contains(entry.id)
                                    ? "circle"
                                    : "checkmark.circle.fill")
                                    .foregroundColor(excludedTOC.contains(entry.id)
                                        ? .secondary
                                        : .green)
                                    .onTapGesture {
                                        toggleTOC(entry.id)
                                    }

                                Text(entry.title)
                                    .padding(.leading, Double(entry.level) * 16)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .listStyle(.plain)
                    .frame(minHeight: 150)
                }
            }

            Spacer()

            // Import progress
            if isImporting {
                VStack(spacing: 8) {
                    ProgressView(value: importProgress)
                        .progressViewStyle(.linear)
                    Text("Importing... \(Int(importProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Action buttons
            HStack {
                if isImporting {
                    Button("Cancel") {
                        isImporting = false
                    }
                    .buttonStyle(.bordered)
                }

                Spacer()

                Button("Import") {
                    startImport()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedFileURL == nil || isImporting)
            }
        }
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        VStack(spacing: 16) {
            // Cover placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.1))
                    .aspectRatio(2/3, contentMode: .fit)
                    .frame(maxHeight: 300)

                if let coverData = project.coverImageData,
                   let nsImage = NSImage(data: coverData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("Cover Art")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Metadata
            VStack(alignment: .leading, spacing: 12) {
                metadataRow(label: "Title", value: project.title)
                metadataRow(label: "Author", value: project.author)
                metadataRow(label: "Chapters", value: "\(project.chapters.count)")
                metadataRow(label: "Scenes", value: "\(project.scenes.count)")
                metadataRow(label: "Characters", value: "\(project.characters.count)")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.05))
            )

            Spacer()
        }
    }

    // MARK: - Helpers

    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            Text(value)
                .font(.subheadline)
        }
    }

    private func selectEPUB() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [UTType(filenameExtension: "epub") ?? .data]
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            selectedFileURL = panel.url
        }
    }

    private func toggleTOC(_ id: String) {
        if excludedTOC.contains(id) {
            excludedTOC.remove(id)
        } else {
            excludedTOC.insert(id)
        }
    }

    private func startImport() {
        isImporting = true
        importProgress = 0
        Task {
            for step in 0...10 {
                try? await Task.sleep(for: .milliseconds(300))
                importProgress = Double(step) / 10.0
            }
            isImporting = false
            model.updateStageStatus(.import, status: .complete)
        }
    }
}
