import SwiftUI
import StudioDomain

struct SoundDesignScreen: View {
    let project: ProjectViewState
    @EnvironmentObject var model: StudioApplicationModel
    @State private var selectedSoundSceneID: StudioDomain.Scene.ID?
    @State private var musicPrompt: String = ""
    @State private var ambiencePrompt: String = ""
    @State private var musicVolume: Double = 0.7
    @State private var ambienceVolume: Double = 0.5
    @State private var fadeIn: Double = 0.5
    @State private var fadeOut: Double = 1.0
    @State private var dialogueDucking = true

    var body: some View {
        HSplitView {
            // Scene list
            sceneListPanel
                .frame(minWidth: 250)
                .padding()

            // Sound design editor
            soundEditorPanel
                .frame(minWidth: 450)
                .padding()
        }
    }

    // MARK: - Scene List

    private var sceneListPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Sound Design")
                .font(.title2)
                .fontWeight(.bold)

            List(project.scenes.sorted { $0.order < $1.order }) { scene in
                HStack {
                    VStack(alignment: .leading) {
                        Text(scene.title)
                            .font(.body)
                        if let location = scene.location {
                            Text(location)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    // Status indicator
                    if let design = project.soundDesigns.first(where: { $0.sceneID == scene.id }) {
                        if design.generatedMusicData != nil || design.generatedAmbienceData != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else if !design.musicPrompt.isEmpty || !design.ambiencePrompt.isEmpty {
                            Image(systemName: "circle.dotted")
                                .foregroundColor(.blue)
                        }
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedSoundSceneID = scene.id
                    loadSettings(for: scene)
                }
            }
            .listStyle(.plain)
        }
    }

    // MARK: - Sound Editor

    private var soundEditorPanel: some View {
        Group {
            if let sceneID = selectedSoundSceneID,
               let scene = project.scenes.first(where: { $0.id == sceneID }) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Scene info
                        VStack(alignment: .leading, spacing: 4) {
                            Text(scene.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(scene.summary)
                                .font(.body)
                                .foregroundColor(.secondary)
                            if let mood = scene.mood {
                                HStack {
                                    Image(systemName: "theatermasks")
                                        .font(.caption)
                                    Text("Mood: \(mood)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Divider()

                        // Music
                        soundSection(
                            icon: "music.note",
                            title: "Background Music",
                            prompt: $musicPrompt,
                            placeholder: "Describe the music... (e.g., 'Subdued, pulsing tension. Low strings.')"
                        )

                        // Ambience
                        soundSection(
                            icon: "leaf",
                            title: "Ambience",
                            prompt: $ambiencePrompt,
                            placeholder: "Describe the ambient sound... (e.g., 'Quiet apartment at dusk. Distant traffic.')"
                        )

                        Divider()

                        // Controls
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Mix Settings")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            HStack(spacing: 20) {
                                sliderControl(
                                    label: "Music Volume",
                                    value: $musicVolume,
                                    icon: "music.note"
                                )
                                sliderControl(
                                    label: "Ambience Volume",
                                    value: $ambienceVolume,
                                    icon: "leaf"
                                )
                            }

                            HStack(spacing: 20) {
                                sliderControl(
                                    label: "Fade In",
                                    value: $fadeIn,
                                    range: 0...3,
                                    format: "%.1fs",
                                    icon: "arrow.right.to.line"
                                )
                                sliderControl(
                                    label: "Fade Out",
                                    value: $fadeOut,
                                    range: 0...5,
                                    format: "%.1fs",
                                    icon: "arrow.left.to.line"
                                )
                            }

                            Toggle(isOn: $dialogueDucking) {
                                HStack(spacing: 4) {
                                    Image(systemName: "waveform")
                                        .font(.caption)
                                    Text("Dialogue Ducking")
                                        .font(.body)
                                }
                            }
                            .toggleStyle(.switch)
                        }

                        Divider()

                        // Waveform preview
                        if let design = project.soundDesigns.first(where: { $0.sceneID == scene.id }),
                           let musicData = design.generatedMusicData {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Music Waveform")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                MockWaveformView(data: musicData)
                                    .frame(height: 50)
                            }
                        }
                        if let design = project.soundDesigns.first(where: { $0.sceneID == scene.id }),
                           let ambienceData = design.generatedAmbienceData {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ambience Waveform")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                MockWaveformView(data: ambienceData)
                                    .frame(height: 50)
                            }
                        }

                        // Actions
                        HStack {
                            Button("Generate") { }
                                .buttonStyle(.borderedProminent)

                            Button("Regenerate") { }
                                .buttonStyle(.bordered)

                            Spacer()
                        }
                    }
                    .padding(.bottom, 20)
                }
            } else {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Select a scene to design its sound")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }

    // MARK: - Subviews

    private func soundSection(
        icon: String,
        title: String,
        prompt: Binding<String>,
        placeholder: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
                Spacer()
                if !prompt.wrappedValue.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                }
            }

            TextEditor(text: prompt)
                .font(.body)
                .frame(minHeight: 60)
                .padding(4)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if prompt.wrappedValue.isEmpty {
                        Text(placeholder)
                            .font(.body)
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 10)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private func sliderControl(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double> = 0...1,
        format: String = "%.0f%%",
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: format, value.wrappedValue * (format.contains("%") ? 100 : 1)))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            Slider(value: value, in: range)
                .controlSize(.small)
        }
    }

    // MARK: - Helpers

    private func loadSettings(for scene: StudioDomain.Scene) {
        if let design = project.soundDesigns.first(where: { $0.sceneID == scene.id }) {
            musicPrompt = design.musicPrompt
            ambiencePrompt = design.ambiencePrompt
            musicVolume = design.musicVolume
            ambienceVolume = design.ambienceVolume
            fadeIn = design.fadeInDuration
            fadeOut = design.fadeOutDuration
            dialogueDucking = design.dialogueDucking
        } else {
            musicPrompt = ""
            ambiencePrompt = ""
            musicVolume = 0.7
            ambienceVolume = 0.5
            fadeIn = 0.5
            fadeOut = 1.0
            dialogueDucking = true
        }
    }
}
