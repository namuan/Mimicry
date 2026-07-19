import SwiftUI
import StudioDomain

struct GenerateScreen: View {
    let project: ProjectViewState
    @EnvironmentObject var model: StudioApplicationModel
    @State private var selectedScope: GenerationScope = .scene

    var body: some View {
        VStack(spacing: 0) {
            // Scope selection and estimated stats
            scopePanel
                .padding()

            Divider()

            // Job queue and progress
            jobsPanel
                .padding()
        }
    }

    // MARK: - Scope Panel

    private var scopePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generate")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 12) {
                ForEach(GenerationScope.allCases, id: \.self) { scope in
                    scopeButton(scope)
                }
            }

            // Stats for selected scope
            VStack(spacing: 6) {
                HStack {
                    statsCard(
                        icon: "clock",
                        label: "Estimated",
                        value: estimatedDuration
                    )
                    statsCard(
                        icon: "cpu",
                        label: "Compute",
                        value: estimatedCompute
                    )
                    statsCard(
                        icon: "speaker.wave.2",
                        label: "Audio",
                        value: estimatedOutputSize
                    )
                }

                ProgressView(value: overallProgress)
                    .progressViewStyle(.linear)
                    .tint(.green)

                Text("\(Int(overallProgress * 100))% complete")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondary.opacity(0.05))
            )

            HStack {
                Spacer()
                Button("Generate \(selectedScope.rawValue)") { }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
        }
    }

    private func scopeButton(_ scope: GenerationScope) -> some View {
        Button {
            selectedScope = scope
        } label: {
            VStack(spacing: 4) {
                Image(systemName: scopeIcon(scope))
                    .font(.title3)
                Text(scope.rawValue)
                    .font(.caption)
                    .fontWeight(selectedScope == scope ? .bold : .regular)
            }
            .frame(width: 80, height: 60)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedScope == scope
                        ? Color.accentColor.opacity(0.15)
                        : Color.secondary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(selectedScope == scope
                        ? Color.accentColor
                        : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private func scopeIcon(_ scope: GenerationScope) -> String {
        switch scope {
        case .line: "text.quote"
        case .scene: "film"
        case .chapter: "book.pages"
        case .book: "books.vertical"
        }
    }

    private func statsCard(icon: String, label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
            Text(value)
                .font(.headline)
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.05))
        )
    }

    private var estimatedDuration: String {
        switch selectedScope {
        case .line: "~5s"
        case .scene: "~2m"
        case .chapter: "~8m"
        case .book: "~22m"
        }
    }

    private var estimatedCompute: String {
        switch selectedScope {
        case .line: "Low"
        case .scene: "Medium"
        case .chapter: "High"
        case .book: "Very High"
        }
    }

    private var estimatedOutputSize: String {
        switch selectedScope {
        case .line: "~0.5 MB"
        case .scene: "~4 MB"
        case .chapter: "~18 MB"
        case .book: "~55 MB"
        }
    }

    private var overallProgress: Double {
        let jobs = project.generationJobs
        guard !jobs.isEmpty else { return 0 }
        let total = jobs.reduce(0.0) { $0 + $1.progress }
        return total / Double(jobs.count)
    }

    // MARK: - Jobs Panel

    private var jobsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Generation Queue")
                .font(.headline)
                .foregroundColor(.secondary)

            if project.generationJobs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No generation jobs yet. Select a scope and generate.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 40)
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(project.generationJobs) { job in
                        jobRow(job)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private func jobRow(_ job: GenerationJob) -> some View {
        HStack(spacing: 12) {
            // Status icon
            statusIcon(for: job.status)
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(job.type.rawValue)
                        .font(.body)
                        .fontWeight(.medium)
                    Text("· \(job.scope.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Progress bar
                if job.status == .running {
                    ProgressView(value: job.progress)
                        .progressViewStyle(.linear)
                        .tint(.blue)
                }

                // Log messages (last 2)
                if job.status == .running || job.status == .completed || job.status == .failed {
                    Text(job.logMessages.suffix(2).joined(separator: " "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                // Timestamp
                if let completed = job.completedAt {
                    Text(RelativeDateTimeFormatter().localizedString(for: completed, relativeTo: Date()))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 6) {
                switch job.status {
                case .running:
                    Button("Cancel") { model.cancelJob(job.id) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.red)
                case .failed:
                    Button("Retry") { model.retryJob(job.id) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.orange)
                    Button("Dismiss") { model.cancelJob(job.id) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                case .queued:
                    Button("Cancel") { model.cancelJob(job.id) }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                case .cancelled:
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
    }

    private func statusIcon(for status: JobStatus) -> some View {
        switch status {
        case .queued:
            return Image(systemName: "clock.fill")
                .foregroundColor(.secondary)
        case .running:
            return Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundColor(.blue)
        case .completed:
            return Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            return Image(systemName: "xmark.octagon.fill")
                .foregroundColor(.red)
        case .cancelled:
            return Image(systemName: "slash.circle.fill")
                .foregroundColor(.secondary)
        }
    }
}
