import SwiftUI
import StudioDomain

struct CharactersScreen: View {
    let project: ProjectViewState
    @EnvironmentObject var model: StudioApplicationModel
    @State private var selectedCharacterID: Character.ID?
    @State private var showDuplicateAlert = false
    @State private var duplicatePair: (Character, Character)?

    var body: some View {
        VStack(spacing: 0) {
            // Header with duplicate warning
            if hasDuplicates {
                duplicateBanner
            }

            HSplitView {
                // Character list
                characterListPanel
                    .frame(minWidth: 280)
                    .padding()

                // Character detail
                characterDetailPanel
                    .frame(minWidth: 400)
                    .padding()
            }
        }
    }

    // MARK: - Duplicate Banner

    private var hasDuplicates: Bool {
        project.characters.contains { $0.notes.contains("DUPLICATE") }
    }

    private var duplicateBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            Text("Possible duplicate characters detected")
                .font(.subheadline)
            Spacer()
            Button("Review") {
                showDuplicateAlert = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .onTapGesture { showDuplicateAlert = true }
    }

    // MARK: - Character List

    private var characterListPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Characters")
                .font(.title2)
                .fontWeight(.bold)

            List(project.characters) { character in
                characterRow(character)
                    .padding(.vertical, 4)
                    .background(
                        selectedCharacterID == character.id
                            ? Color.accentColor.opacity(0.1)
                            : Color.clear
                    )
                    .cornerRadius(8)
                    .onTapGesture {
                        selectedCharacterID = character.id
                    }
            }
            .listStyle(.plain)

            HStack {
                Button("Add Character") { }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Spacer()
            }
        }
    }

    private func characterRow(_ character: Character) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(character.isNarrator ? Color.purple : Color.blue)
                    .frame(width: 8, height: 8)

                Text(character.name)
                    .font(.headline)

                if character.isNarrator {
                    Text("NARRATOR")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(4)
                }

                Spacer()

                Text("\(character.sceneAppearances.count) scenes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if !character.aliases.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "tag")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(character.aliases.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            if !character.notes.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text(character.notes)
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .lineLimit(2)
                }
            }
        }
    }

    // MARK: - Character Detail

    private var characterDetailPanel: some View {
        Group {
            if let charID = selectedCharacterID,
               let character = project.characters.first(where: { $0.id == charID }) {
                VStack(alignment: .leading, spacing: 16) {
                    // Name and type
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(character.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(character.description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        Spacer()

                        // Narrator toggle
                        Toggle(isOn: Binding(
                            get: { character.isNarrator },
                            set: { _ in model.setNarrator(character.id) }
                        )) {
                            Text("Narrator")
                                .font(.caption)
                        }
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    }

                    Divider()

                    // Aliases
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aliases")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        if character.aliases.isEmpty {
                            Text("No aliases defined")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(character.aliases, id: \.self) { alias in
                                HStack {
                                    Text(alias)
                                        .font(.body)
                                    Spacer()
                                    Button(action: {}) {
                                        Image(systemName: "xmark.circle")
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.secondary.opacity(0.08))
                                )
                            }
                        }
                    }

                    // Scene appearances
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Appears In")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        ForEach(character.sceneAppearances, id: \.self) { sceneID in
                            let matchingScene = project.scenes.first(where: { $0.id == sceneID })
                            if let scene = matchingScene,
                               let chapter = project.chapters.first(where: { $0.id == scene.chapterID }) {
                                HStack {
                                    Image(systemName: "film")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                    Text("\(chapter.title) — \(scene.title)")
                                        .font(.body)
                                    Spacer()
                                    Button("Go") {
                                        model.navigateToScene(sceneID, chapterID: chapter.id)
                                        model.selectedStage = .script
                                    }
                                    .buttonStyle(.link)
                                    .controlSize(.small)
                                }
                            }
                        }
                    }

                    Divider()

                    // Actions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Actions")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            if character.notes.contains("DUPLICATE") {
                                Button("Review Duplicate") {
                                    showDuplicateAlert = true
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .tint(.orange)
                            }

                            Button("Merge with...") { }
                                .buttonStyle(.bordered)
                                .controlSize(.small)

                            if !character.isNarrator {
                                Button("Set as Narrator") {
                                    model.setNarrator(character.id)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }

                            Spacer()
                        }
                    }

                    Spacer()
                }
                // Duplicate alert
                .alert("Duplicate Character Detected", isPresented: $showDuplicateAlert) {
                    Button("Merge Characters") {
                        // Find the duplicate pair
                        guard let doctor = project.characters.first(where: { $0.name.contains("Dr.") }),
                              let elena = project.characters.first(where: { $0.name.contains("Elena") })
                        else { return }
                        model.mergeCharacters(elena.id, doctor.id)
                        selectedCharacterID = elena.id
                    }
                    Button("Keep Separate", role: .cancel) { }
                } message: {
                    Text("Dr. Helena Vance may be an alias used by Elena Vasquez. Both are female intelligence contacts associated with Vienna.\n\nWould you like to merge them into one character?")
                }
            } else {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Select a character to view details")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }
}
