import SwiftUI
import AVFoundation
import StudioDomain

struct VoicesScreen: View {
    let project: ProjectViewState
    @EnvironmentObject var model: StudioApplicationModel
    @State private var selectedCharacterID: Character.ID?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var isPlayingPreview = false

    var body: some View {
        HSplitView {
            // Character list
            characterCardsPanel
                .frame(minWidth: 300)
                .padding()

            // Voice assignment detail
            voiceDetailPanel
                .frame(minWidth: 400)
                .padding()
        }
    }

    // MARK: - Character Cards

    private var characterCardsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Characters & Voices")
                .font(.title2)
                .fontWeight(.bold)

            ScrollView {
                VStack(spacing: 12) {
                    // Narrator first
                    if let narrator = project.characters.first(where: { $0.isNarrator }) {
                        characterVoiceCard(narrator, isNarrator: true)
                    }

                    // Other characters
                    ForEach(project.characters.filter { !$0.isNarrator }) { character in
                        characterVoiceCard(character, isNarrator: false)
                    }
                }
            }
        }
    }

    private func characterVoiceCard(_ character: Character, isNarrator: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if isNarrator {
                    Image(systemName: "megaphone.fill")
                        .foregroundColor(.purple)
                }
                Text(character.name)
                    .font(.headline)
                if isNarrator {
                    Text("NARRATOR")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.purple)
                }
                Spacer()

                // Voice status indicator
                if character.voiceProfileID != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                }
            }

            if let voiceID = character.voiceProfileID,
               let voice = project.voiceProfiles.first(where: { $0.id == voiceID }) {
                HStack {
                    Text(voice.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    if let accent = voice.accent {
                        Text("· \(accent)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Text("No voice assigned")
                    .font(.subheadline)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(selectedCharacterID == character.id
                    ? Color.accentColor.opacity(0.1)
                    : Color.secondary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(selectedCharacterID == character.id
                    ? Color.accentColor
                    : Color.clear, lineWidth: 2)
        )
        .onTapGesture {
            selectedCharacterID = character.id
        }
    }

    // MARK: - Voice Detail

    private var voiceDetailPanel: some View {
        Group {
            if let charID = selectedCharacterID,
               let character = project.characters.first(where: { $0.id == charID }) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Voice Selection: \(character.name)")
                        .font(.title2)
                        .fontWeight(.bold)

                    if let voiceID = character.voiceProfileID,
                       let assignedVoice = project.voiceProfiles.first(where: { $0.id == voiceID }) {
                        // Currently assigned voice
                        voiceDetailCard(
                            voice: assignedVoice,
                            isAssigned: true,
                            onPreview: { playPreview(assignedVoice) },
                            onRemove: {
                                model.updateCharacterVoice(character.id, voiceProfileID: VoiceProfile.ID())
                            }
                        )
                    }

                    Divider()

                    // Voice candidates
                    Text("Available Voices")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    let candidates = project.voiceProfiles
                        .filter { $0.id != character.voiceProfileID && !$0.isNarratorVoice }

                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(candidates) { candidate in
                                voiceDetailCard(
                                    voice: candidate,
                                    isAssigned: false,
                                    onPreview: { playPreview(candidate) },
                                    onAssign: {
                                        model.updateCharacterVoice(character.id, voiceProfileID: candidate.id)
                                    }
                                )
                            }
                        }
                    }

                    Divider()

                    HStack {
                        if isPlayingPreview {
                            Button(action: stopPreview) {
                                Label("Stop Preview", systemImage: "stop.fill")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.red)
                        }

                        Spacer()

                        Button("Regenerate Candidates") { }
                            .buttonStyle(.bordered)
                            .controlSize(.small)

                        Button("Generate New Voice...") { }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }
                }
            } else {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "waveform")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("Select a character to assign a voice")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }

    private func voiceDetailCard(
        voice: VoiceProfile,
        isAssigned: Bool,
        onPreview: @escaping () -> Void,
        onRemove: (() -> Void)? = nil,
        onAssign: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(voice.name)
                            .font(.headline)
                        if isAssigned {
                            Text("ASSIGNED")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    Text(voice.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }

            HStack(spacing: 8) {
                if let accent = voice.accent {
                    tagChip(accent, color: .blue)
                }
                if let age = voice.ageRange {
                    tagChip(age, color: .green)
                }
                if let tone = voice.tone {
                    tagChip(tone, color: .purple)
                }
            }

            if let sampleText = voice.sampleText {
                Text("\"\(sampleText)\"")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(2)
            }

            // Playback controls
            HStack {
                Button(action: onPreview) {
                    Label("Preview", systemImage: isPlayingPreview ? "stop.circle" : "play.circle")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                // Mock waveform visualization
                if let audioData = voice.previewAudioData, !audioData.isEmpty {
                    MockWaveformView(data: audioData)
                        .frame(height: 30)
                        .opacity(0.5)
                }

                Spacer()

                if let onAssign = onAssign {
                    Button("Assign") {
                        onAssign()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                if let onRemove = onRemove {
                    Button("Remove") {
                        onRemove()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isAssigned ? Color.green.opacity(0.05) : Color.secondary.opacity(0.05))
        )
    }

    // MARK: - Helpers

    private func tagChip(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(4)
    }

    private func playPreview(_ voice: VoiceProfile) {
        guard let data = voice.previewAudioData, !data.isEmpty else { return }
        isPlayingPreview = true
        // In a real implementation, play through AVAudioPlayer
        // For the mock, we just simulate playback
        Task {
            try? await Task.sleep(for: .seconds(2))
            isPlayingPreview = false
        }
    }

    private func stopPreview() {
        isPlayingPreview = false
    }
}
