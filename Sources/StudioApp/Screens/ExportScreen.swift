import SwiftUI
import StudioDomain
import AppKit

struct ExportScreen: View {
    let project: ProjectViewState
    @EnvironmentObject var model: StudioApplicationModel
    @State private var selectedFormat: ExportFormat = .m4a
    @State private var outputDirectory: URL?
    @State private var chapterNamingTemplate = "{number} - {title}"
    @State private var includeCover = true
    @State private var includeMetadata = true
    @State private var normalizeAudio = true
    @State private var targetLUFS: Double = -16
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
    @State private var validationResults: [ReviewIssueViewState] = []
    @State private var exportComplete = false

    var body: some View {
        HSplitView {
            // Settings panel
            settingsPanel
                .frame(minWidth: 350)
                .padding()

            // Validation and export panel
            rightPanel
                .frame(minWidth: 350)
                .padding()
        }
    }

    // MARK: - Settings Panel

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Export")
                .font(.title2)
                .fontWeight(.bold)

            // Format
            VStack(alignment: .leading, spacing: 6) {
                Text("Format")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Picker("Format", selection: $selectedFormat) {
                    ForEach(ExportFormat.allCases, id: \.self) { fmt in
                        Text(formatLabel(fmt)).tag(fmt)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Output directory
            VStack(alignment: .leading, spacing: 6) {
                Text("Output Directory")
                    .font(.headline)
                    .foregroundColor(.secondary)

                HStack {
                    if let dir = outputDirectory {
                        Text(dir.path)
                            .font(.body)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                    } else {
                        Text("Choose output location...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Browse...") {
                        selectOutputDirectory()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }

            // Chapter naming
            VStack(alignment: .leading, spacing: 6) {
                Text("Chapter Naming")
                    .font(.headline)
                    .foregroundColor(.secondary)

                TextField("Template", text: $chapterNamingTemplate)
                    .textFieldStyle(.roundedBorder)

                Text("Available variables: {number}, {title}")
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Preview
                if let firstChapter = project.chapters.first {
                    let preview = chapterNamingTemplate
                        .replacingOccurrences(of: "{number}", with: "\(firstChapter.number)")
                        .replacingOccurrences(of: "{title}", with: firstChapter.title)
                    Text("Example: \(preview).\(selectedFormat.rawValue.lowercased())")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }

            // Options
            VStack(alignment: .leading, spacing: 8) {
                Text("Options")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Toggle("Include cover image", isOn: $includeCover)
                    .toggleStyle(.checkbox)

                Toggle("Embed metadata", isOn: $includeMetadata)
                    .toggleStyle(.checkbox)

                Toggle("Normalize audio", isOn: $normalizeAudio)
                    .toggleStyle(.checkbox)

                if normalizeAudio {
                    HStack {
                        Text("Target LUFS:")
                            .font(.caption)
                        Stepper(
                            String(format: "%.1f", targetLUFS),
                            value: $targetLUFS,
                            in: -30...0,
                            step: 0.5
                        )
                        .controlSize(.small)
                    }
                    .padding(.leading, 20)
                }
            }

            Spacer()

            // Export button
            HStack {
                Spacer()
                Button(action: startExport) {
                    Label(
                        isExporting ? "Exporting..." : "Export Audiobook",
                        systemImage: isExporting ? "arrow.triangle.2.circlepath" : "square.and.arrow.up"
                    )
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isExporting || outputDirectory == nil)
            }
        }
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Validation
            VStack(alignment: .leading, spacing: 8) {
                Text("Validation")
                    .font(.headline)
                    .foregroundColor(.secondary)

                if validationResults.isEmpty && !isExporting {
                    HStack {
                        Button("Validate") {
                            runValidation()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        Spacer()
                    }
                }

                if !validationResults.isEmpty {
                    VStack(spacing: 4) {
                        let errors = validationResults.filter { $0.severity == .error }
                        let warnings = validationResults.filter { $0.severity == .warning }
                        let infos = validationResults.filter { $0.severity == .info }

                        if errors.isEmpty && warnings.isEmpty {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Validation passed")
                                    .foregroundColor(.green)
                                Spacer()
                            }
                        }

                        if !errors.isEmpty {
                            Label("\(errors.count) errors", systemImage: "xmark.octagon.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        if !warnings.isEmpty {
                            Label("\(warnings.count) warnings", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                        }
                        if !infos.isEmpty {
                            Label("\(infos.count) notes", systemImage: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.caption)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondary.opacity(0.05))
                    )
                }
            }

            // Export progress
            if isExporting || exportComplete {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Export Progress")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    ProgressView(value: exportProgress)
                        .progressViewStyle(.linear)
                        .tint(exportComplete ? .green : .blue)

                    HStack {
                        if exportComplete {
                            Label("Export complete!", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.body)
                        } else {
                            Text("Exporting... \(Int(exportProgress * 100))%")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if isExporting {
                            Button("Cancel") {
                                isExporting = false
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.red)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.05))
                )
            }

            // Completion actions
            if exportComplete {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Output Files")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    ForEach(project.chapters.sorted { $0.order < $1.order }) { chapter in
                        HStack {
                            Image(systemName: "music.note.list")
                                .foregroundColor(.blue)
                            let filename = chapterNamingTemplate
                                .replacingOccurrences(of: "{number}", with: "\(chapter.number)")
                                .replacingOccurrences(of: "{title}", with: chapter.title)
                            Text("\(filename).\(selectedFormat.rawValue.lowercased())")
                                .font(.body)
                            Spacer()
                            Text("~12 MB")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    HStack {
                        Spacer()
                        Button("Reveal in Finder") {
                            if let dir = outputDirectory {
                                NSWorkspace.shared.open(dir)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.05))
                )
            }

            Spacer()
        }
    }

    // MARK: - Helpers

    private func formatLabel(_ format: ExportFormat) -> String {
        switch format {
        case .wav: "WAV (Lossless)"
        case .mp3: "MP3"
        case .m4a: "M4A (AAC)"
        case .flac: "FLAC (Lossless)"
        }
    }

    private func selectOutputDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK {
            outputDirectory = panel.url
        }
    }

    private func runValidation() {
        // Run mock validation
        validationResults = project.reviewIssues
            .filter { !$0.isResolved }
            .map { ReviewIssueViewState(issue: $0) }
    }

    private func startExport() {
        guard outputDirectory != nil else { return }
        isExporting = true
        exportProgress = 0
        exportComplete = false

        // Simulate export
        Task {
            for step in 0...10 {
                try? await Task.sleep(for: .milliseconds(500))
                exportProgress = Double(step) / 10.0
            }
            exportComplete = true
            isExporting = false
            model.updateStageStatus(.export, status: .complete)
        }
    }
}
