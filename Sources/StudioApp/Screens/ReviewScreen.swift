import SwiftUI
import StudioDomain

struct ReviewScreen: View {
    let project: ProjectViewState
    @EnvironmentObject var model: StudioApplicationModel
    @State private var filterByStage: WorkflowStage? = nil
    @State private var filterBySeverity: IssueSeverity? = nil
    @State private var showResolved = false

    var body: some View {
        VStack(spacing: 0) {
            // Header with filter controls
            filterBar
                .padding()

            Divider()

            // Issues list
            issuesList
                .padding()
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Review")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Text("\(filteredIssues.count) issues")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if filteredIssues.contains(where: { $0.severity == .error }) {
                    Image(systemName: "exclamationmark.octagon.fill")
                        .foregroundColor(.red)
                }
            }

            // Stage filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    filterChip(label: "All", isSelected: filterByStage == nil) {
                        filterByStage = nil
                    }
                    ForEach(WorkflowStage.allCases, id: \.self) { stage in
                        let count = project.reviewIssues.filter { !$0.isResolved && $0.relatedStage == stage }.count
                        if count > 0 {
                            filterChip(label: "\(stage.rawValue) (\(count))", isSelected: filterByStage == stage) {
                                filterByStage = filterByStage == stage ? nil : stage
                            }
                        }
                    }
                }
            }

            // Severity + resolved toggle
            HStack {
                Picker("Severity", selection: $filterBySeverity) {
                    Text("All Severities").tag(nil as IssueSeverity?)
                    ForEach(IssueSeverity.allCases, id: \.self) { severity in
                        Text(severity.rawValue).tag(severity as IssueSeverity?)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 250)

                Spacer()

                Toggle("Show resolved", isOn: $showResolved)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
            }
        }
    }

    private func filterChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Issues List

    private var issuesList: some View {
        SwiftUI.Group {
            if filteredIssues.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green.opacity(0.7))
                    Text("All issues resolved! �?")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("Your production is ready for the next stage.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    // Group by severity
                    ForEach(IssueSeverity.allCases, id: \.self) { severity in
                        let severityIssues = filteredIssues.filter { $0.severity == severity }
                        if !severityIssues.isEmpty {
                            Section {
                                ForEach(severityIssues) { issue in
                                    issueRow(issue)
                                }
                            } header: {
                                Label(severity.rawValue, systemImage: severityIcon(for: severity))
                                    .foregroundColor(severityColor(for: severity))
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
    }

    private func issueRow(_ issue: ReviewIssueViewState) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: issueIcon(for: issue.type))
                .foregroundColor(severityColor(for: issue.severity))
                .font(.title2)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(issue.title)
                        .font(.body)
                        .fontWeight(.semibold)

                    Spacer()

                    Text(issue.relatedStage.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(4)
                }

                Text(issue.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                HStack(spacing: 8) {
                    Text(issue.type.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Go to Issue") {
                        model.navigateToIssue(issue)
                    }
                    .buttonStyle(.link)
                    .controlSize(.small)

                    if !issue.isResolved {
                        Button("Resolve") {
                            model.resolveIssue(issue.id)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .tint(.green)
                    }
                }
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - Helpers

    private var filteredIssues: [ReviewIssueViewState] {
        var issues = project.reviewIssues
            .filter { showResolved || !$0.isResolved }
            .map { ReviewIssueViewState(issue: $0) }

        if let stage = filterByStage {
            issues = issues.filter { $0.relatedStage == stage }
        }
        if let severity = filterBySeverity {
            issues = issues.filter { $0.severity == severity }
        }

        return issues.sorted { $0.severity > $1.severity }
    }

    private func severityIcon(for severity: IssueSeverity) -> String {
        switch severity {
        case .info: "info.circle.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .error: "xmark.octagon.fill"
        }
    }

    private func severityColor(for severity: IssueSeverity) -> Color {
        switch severity {
        case .info: .blue
        case .warning: .orange
        case .error: .red
        }
    }

    private func issueIcon(for type: ReviewIssueType) -> String {
        switch type {
        case .uncertainSpeaker: "person.fill.questionmark"
        case .duplicateCharacter: "person.2.slash"
        case .missingVoice: "waveform.slash"
        case .missingAudio: "speaker.slash"
        case .staleDialogue: "clock.badge.exclamationmark"
        case .failedGeneration: "xmark.shield"
        case .abruptSceneTransition: "rectangle.split.2x1"
        case .exportValidation: "checklist"
        }
    }
}
