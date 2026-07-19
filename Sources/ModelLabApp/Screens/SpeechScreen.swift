import SwiftUI
import AVFoundation

struct SpeechScreen: View {
    @EnvironmentObject var labModel: ModelLabViewModel
    @State private var inputText = "The corridor was completely dark. Elena pressed her back against the cold wall."
    @State private var voiceName = "Samantha"
    @State private var speakingRate: Double = 1.0
    @State private var isGenerating = false
    @State private var outputInfo = ""
    @State private var audioPlayer: AVAudioPlayer?

    private let availableVoices = ["Samantha", "Daniel", "Karen", "Fiona", "Moira", "Veena", "Alex"]

    var body: some View {
        VStack(spacing: 12) {
            Text("Speech Experiment")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                Text("Input Text")
                    .font(.headline)
                    .foregroundColor(.secondary)

                TextEditor(text: $inputText)
                    .font(.body)
                    .frame(minHeight: 60)
                    .padding(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding(.horizontal)

            // Parameters
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Voice").font(.caption).foregroundColor(.secondary)
                    Picker("Voice", selection: $voiceName) {
                        ForEach(availableVoices, id: \.self) { voice in
                            Text(voice).tag(voice)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 180)
                }
                VStack(alignment: .leading) {
                    Text("Speaking Rate: \(String(format: "%.1f", speakingRate))x").font(.caption).foregroundColor(.secondary)
                    Slider(value: $speakingRate, in: 0.5...3, step: 0.1)
                        .frame(width: 200)
                }
                Spacer()
                Button("Generate Speech") {
                    generateSpeech()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating)
            }
            .padding(.horizontal)

            Divider()

            // Output
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Output")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    if audioPlayer != nil {
                        HStack(spacing: 8) {
                            Button(action: playAudio) {
                                Label("Play", systemImage: "play.fill")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.green)

                            Button(action: stopAudio) {
                                Label("Stop", systemImage: "stop.fill")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                            .tint(.red)
                        }
                    }
                }

                ScrollView {
                    if outputInfo.isEmpty {
                        Text("Generated audio information will appear here...")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        Text(outputInfo)
                            .font(.body.monospaced())
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding(.top)
    }

    private func generateSpeech() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isGenerating = true
        outputInfo = ""
        audioPlayer = nil

        Task {
            let (info, audioData) = await labModel.runSpeechGeneration(
                text: inputText,
                voiceName: voiceName,
                rate: speakingRate
            )
            isGenerating = false
            outputInfo = info

            if let data = audioData, !data.isEmpty {
                do {
                    let player = try AVAudioPlayer(data: data)
                    player.prepareToPlay()
                    audioPlayer = player
                } catch {
                    outputInfo += "\n\nPlayback error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func playAudio() {
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }

    private func stopAudio() {
        audioPlayer?.stop()
    }
}
