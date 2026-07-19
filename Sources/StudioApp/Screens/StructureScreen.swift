import SwiftUI
import StudioDomain

struct StructureScreen: View {
    let project: ProjectViewState
    @EnvironmentObject var model: StudioApplicationModel
    @State private var selectedChapterID: Chapter.ID?
    @State private var selectedSceneID: StudioDomain.Scene.ID?

    var body: some View {
        HSplitView {
            // Navigator
            navigatorPanel
                .frame(minWidth: 250)
                .padding()

            // Detail
            detailPanel
                .frame(minWidth: 500)
                .padding()
        }
    }

    // MARK: - Navigator

    private var navigatorPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Structure")
                .font(.title2)
                .fontWeight(.bold)

            List(project.chapters.sorted { $0.order < $1.order }) { chapter in
                DisclosureGroup(isExpanded: binding(for: chapter.id)) {
                    ForEach(project.scenes.filter { $0.chapterID == chapter.id }
                        .sorted { $0.order < $1.order }) { scene in
                        HStack {
                            Circle()
                                .fill(confidenceColor(scene.sceneBoundaryConfidence))
                                .frame(width: 8, height: 8)

                            VStack(alignment: .leading) {
                                Text(scene.title)
                                    .font(.body)
                                Text(scene.summary)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }

                            Spacer()

                            if scene.sceneBoundaryConfidence != nil {
                                Text("\(Int((scene.sceneBoundaryConfidence ?? 0) * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                        .padding(.leading, 12)
                        .background(
                            selectedSceneID == scene.id
                                ? Color.accentColor.opacity(0.1)
                                : Color.clear
                        )
                        .cornerRadius(6)
                        .onTapGesture {
                            let sid = scene.id
                            selectedChapterID = chapter.id
                            selectedSceneID = sid
                        }
                        .contextMenu {
                            Button("Rename...") { }
                            Button("Split at Cursor") { }
                            Button("Merge with Previous") { }
                            Divider()
                            Button("Move Boundary Earlier") { }
                            Button("Move Boundary Later") { }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "book.pages")
                            .foregroundColor(.blue)
                        Text(chapter.title)
                            .font(.headline)
                        Spacer()
                        Text("\(project.scenes.filter { $0.chapterID == chapter.id }.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }

    // MARK: - Detail

    private var detailPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let sceneID = selectedSceneID,
               let scene = project.scenes.first(where: { $0.id == sceneID }) {

                // Scene header
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(scene.title)
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        if let confidence = scene.sceneBoundaryConfidence {
                            HStack(spacing: 4) {
                                Image(systemName: confidence >= 0.85
                                    ? "checkmark.shield.fill"
                                    : "exclamationmark.shield.fill")
                                    .foregroundColor(confidenceColor(confidence))
                                Text("AI Confidence: \(Int(confidence * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(confidenceColor(confidence).opacity(0.1))
                            )
                        }
                    }

                    if let location = scene.location {
                        HStack(spacing: 4) {
                            Image(systemName: "mappin")
                                .font(.caption)
                            Text(location)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }

                    Text(scene.summary)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }

                Divider()

                // Scene text with boundary visualization
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Previous boundary marker
                        boundaryMarker(label: "Previous scene boundary")

                        Text(scene.rawText.isEmpty ? generateMockText(for: scene) : scene.rawText)
                            .font(.body)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.05))
                            )

                        // Next boundary marker
                        boundaryMarker(label: "Next scene boundary")

                        // If low confidence, show review flag
                        if let confidence = scene.sceneBoundaryConfidence, confidence < 0.75 {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("Low confidence boundary — review recommended")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                Spacer()
                                Button("Adjust Boundary") { }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.08))
                            )
                        }
                    }
                }

                // Action toolbar
                HStack(spacing: 8) {
                    Button("Rename Scene") { }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                    Button("Split Here") { }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                    Button("Merge with Previous") { }
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                    Spacer()

                    if let confidence = scene.sceneBoundaryConfidence, confidence < 0.75 {
                        Button("Mark as Reviewed") {
                            // Update stage to needs review / complete
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            } else {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "rectangle.3.group")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Select a scene from the navigator to review its structure")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Helpers

    private func binding(for chapterID: Chapter.ID) -> Binding<Bool> {
        Binding(
            get: { selectedChapterID == chapterID || selectedChapterID == nil },
            set: { _ in }
        )
    }

    private func confidenceColor(_ confidence: Double?) -> Color {
        guard let c = confidence else { return .gray }
        if c >= 0.85 { return .green }
        if c >= 0.70 { return .orange }
        return .red
    }

    private func boundaryMarker(label: String) -> some View {
        HStack {
            Rectangle()
                .fill(Color.orange.opacity(0.5))
                .frame(height: 1)
            Text(label)
                .font(.caption2)
                .foregroundColor(.orange)
            Rectangle()
                .fill(Color.orange.opacity(0.5))
                .frame(height: 1)
        }
        .padding(.vertical, 4)
    }

    private func generateMockText(for scene: StudioDomain.Scene) -> String {
        """
        Elena pressed her back against the cold wall, listening to the footsteps in the stairwell below.

        "Who's there?" she whispered.

        Silence. Then the footsteps resumed — closer now, deliberate.

        The corridor was completely dark. She shouldn't have taken the package. She knew that now, with the certainty of cold metal against her spine.
        """
    }
}
