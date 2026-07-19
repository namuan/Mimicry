import SwiftUI
import StudioDomain

struct ScriptScreen: View {
    let project: ProjectViewState
    @EnvironmentObject var model: StudioApplicationModel
    @State private var editingBlockID: ScriptBlock.ID?
    @State private var editingText: String = ""
    @State private var filterUnresolved = false

    var body: some View {
        HSplitView {
            // Scene navigator
            sceneNavigator
                .frame(minWidth: 250)
                .padding()

            // Script blocks
            scriptBlocksPanel
                .frame(minWidth: 500)
                .padding()
        }
    }

    // MARK: - Scene Navigator

    private var sceneNavigator: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Scenes")
                .font(.title2)
                .fontWeight(.bold)

            List {
                ForEach(project.chapters.sorted { $0.order < $1.order }) { chapter in
                    Section(chapter.title) {
                        ForEach(project.scenes
                            .filter { $0.chapterID == chapter.id }
                            .sorted { $0.order < $1.order }) { scene in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(scene.title)
                                        .font(.body)
                                    Text("\(project.blocks.filter { $0.sceneID == scene.id }.count) blocks")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                let isSceneSelected = model.selectedSceneID == scene.id
                                if isSceneSelected {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                model.selectedChapterID = chapter.id
                                model.selectedSceneID = scene.id
                            }
                        }
                    }
                }
            }
            .listStyle(.sidebar)
        }
    }

    // MARK: - Script Blocks

    private var scriptBlocksPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if let sceneID = model.selectedSceneID,
                   let scene = project.scenes.first(where: { $0.id == sceneID }) {
                    VStack(alignment: .leading) {
                        Text(scene.title)
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(scene.summary)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                } else {
                    Text("Select a scene")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Toggle("Unresolved only", isOn: $filterUnresolved)
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
            }

            Divider()

            // Blocks list
            if let sceneID = model.selectedSceneID {
                let blocks = project.blocks
                    .filter { $0.sceneID == sceneID }
                    .filter { !filterUnresolved || $0.needsSpeakerResolution }
                    .sorted { $0.order < $1.order }

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(blocks) { block in
                            ScriptBlockRow(
                                block: block,
                                characters: project.characters,
                                isEditing: editingBlockID == block.id,
                                editText: editingBlockID == block.id ? $editingText : .constant(""),
                                onBeginEdit: {
                                    editingBlockID = block.id
                                    editingText = block.productionText
                                },
                                onSaveEdit: {
                                    model.updateBlockText(block.id, text: editingText)
                                    editingBlockID = nil
                                },
                                onCancelEdit: {
                                    editingBlockID = nil
                                },
                                onChangeSpeaker: { newSpeakerID in
                                    model.updateBlockSpeaker(block.id, speakerID: newSpeakerID)
                                },
                                onChangeType: { newType in
                                    model.updateBlockType(block.id, type: newType)
                                },
                                onToggleExclude: {
                                    model.toggleBlockExcluded(block.id)
                                },
                                onResetSource: {
                                    model.resetBlockToSource(block.id)
                                }
                            )
                        }
                    }
                }
            } else {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "text.quote")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Select a scene from the navigator to view its script")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Script Block Row

struct ScriptBlockRow: View {
    let block: ScriptBlock
    let characters: [Character]
    let isEditing: Bool
    @Binding var editText: String
    let onBeginEdit: () -> Void
    let onSaveEdit: () -> Void
    let onCancelEdit: () -> Void
    let onChangeSpeaker: (Character.ID?) -> Void
    let onChangeType: (BlockType) -> Void
    let onToggleExclude: () -> Void
    let onResetSource: () -> Void

    @State private var showSpeakerMenu = false
    @State private var showTypeMenu = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                // Speaker label
                speakerLabel
                    .frame(width: 140, alignment: .leading)

                // Text content
                VStack(alignment: .leading, spacing: 6) {
                    if isEditing {
                        TextEditor(text: $editText)
                            .font(.body)
                            .frame(minHeight: 60)
                            .padding(4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.accentColor, lineWidth: 1)
                            )
                    } else {
                        Text(block.productionText)
                            .font(.body)
                    }

                    // Toolbar
                    HStack(spacing: 6) {
                        if isEditing {
                            Button("Save") { onSaveEdit() }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            Button("Cancel") { onCancelEdit() }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                        } else {
                            Button(action: onBeginEdit) {
                                Image(systemName: "pencil")
                            }
                            .buttonStyle(.plain)
                            .help("Edit text")

                            Menu {
                                ForEach(characters) { char in
                                    Button(char.name) {
                                        onChangeSpeaker(char.id)
                                    }
                                }
                                if block.speakerID != nil {
                                    Divider()
                                    Button("Remove Speaker") {
                                        onChangeSpeaker(nil)
                                    }
                                }
                            } label: {
                                Image(systemName: "person.fill")
                            }
                            .buttonStyle(.plain)
                            .help("Change speaker")

                            Menu {
                                ForEach(BlockType.allCases, id: \.self) { type in
                                    Button(type.rawValue) {
                                        onChangeType(type)
                                    }
                                }
                            } label: {
                                Text(block.type.rawValue)
                                    .font(.caption)
                            }
                            .menuStyle(.borderlessButton)
                            .fixedSize()

                            Button(action: onToggleExclude) {
                                Image(systemName: block.isExcluded ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(block.isExcluded ? .red : .secondary)
                            }
                            .buttonStyle(.plain)
                            .help(block.isExcluded ? "Include block" : "Exclude block")

                            if block.productionText != block.sourceText {
                                Button(action: onResetSource) {
                                    Image(systemName: "arrow.counterclockwise")
                                }
                                .buttonStyle(.plain)
                                .help("Restore source text")
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(blockBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(
                    block.needsSpeakerResolution ? Color.orange : Color.clear,
                    lineWidth: 1.5
                )
        )
    }

    private var speakerLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            if block.type == .narration {
                Text("Narrator")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
            } else if let speakerID = block.speakerID,
                      let character = characters.first(where: { $0.id == speakerID }) {
                Text(character.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            } else if block.type == .dialogue {
                HStack(spacing: 4) {
                    Text("???")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            } else if block.type == .thought,
                      let speakerID = block.speakerID,
                      let character = characters.first(where: { $0.id == speakerID }) {
                Text("\(character.name) (thought)")
                    .font(.caption)
                    .foregroundColor(.indigo)
            } else {
                Text("Narrator")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let direction = block.performanceDirection, block.type != .narration {
                Text(direction)
                    .font(.caption2)
                    .foregroundColor(.blue)
                    .lineLimit(2)
            }

            if let confidence = block.speakerConfidence, block.speakerID != nil {
                Text("\(Int(confidence * 100))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var blockBackgroundColor: Color {
        if block.isExcluded {
            return Color.red.opacity(0.05)
        }
        switch block.type {
        case .narration: return Color.secondary.opacity(0.04)
        case .dialogue: return Color.blue.opacity(0.04)
        case .thought: return Color.indigo.opacity(0.04)
        }
    }
}
