import SwiftUI
import StudioDomain

/// The always-visible workflow stage bar at the top of the app.
struct WorkflowBarView: View {
    @EnvironmentObject var model: StudioApplicationModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 0) {
                ForEach(WorkflowStage.allCases, id: \.self) { stage in
                    WorkflowStageButton(
                        stage: stage,
                        status: model.stage(for: stage)?.status ?? .notStarted,
                        isSelected: model.selectedStage == stage
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            model.selectedStage = stage
                        }
                    }

                    if stage != WorkflowStage.allCases.last {
                        WorkflowArrow(
                            isActive: model.stage(for: stage)?.status == .complete
                        )
                    }
                }
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Stage Button

struct WorkflowStageButton: View {
    let stage: WorkflowStage
    let status: WorkflowStageStatus
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                statusIcon
                    .font(.system(size: 16))

                Text(stage.rawValue)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .lineLimit(1)
            }
            .frame(width: 72)
            .padding(.vertical, 6)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .disabled(status == .notStarted && !isSelected)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .notStarted:
            Image(systemName: "circle")
                .foregroundColor(.secondary)
        case .available:
            Image(systemName: "circle.dotted")
                .foregroundColor(.blue)
        case .inProgress:
            ProgressView()
                .scaleEffect(0.7)
        case .needsReview:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
        case .complete:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .outOfDate:
            Image(systemName: "clock.arrow.circlepath")
                .foregroundColor(.yellow)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        }
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color.accentColor.opacity(0.12)
        }
        switch status {
        case .notStarted:
            return Color.clear
        case .inProgress:
            return Color.blue.opacity(0.06)
        case .failed:
            return Color.red.opacity(0.06)
        default:
            return Color.clear
        }
    }
}

// MARK: - Arrow

struct WorkflowArrow: View {
    let isActive: Bool

    var body: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(isActive ? .green : .secondary.opacity(0.4))
            .padding(.horizontal, 2)
    }
}
