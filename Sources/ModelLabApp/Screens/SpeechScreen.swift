import SwiftUI
import AVFoundation
import HuggingFaceCache

struct SpeechScreen: View {
    @EnvironmentObject var labModel: ModelLabViewModel
    @State private var inputText = "The corridor was completely dark. Elena pressed her back against the cold wall."
    @State private var voiceName = "Samantha"
    @State private var speakingRate: Double = 1.0
    @State private var isGenerating = false
    @State private var outputInfo = ""
    @State private var audioPlayer: AVAudioPlayer?
    @State private var engineMode: SpeechEngine = .macOS
    @State private var qwen3ModelPath = ""
    @State private var qwen3Speaker = ""
    @State private var qwen3Instruct = ""

    private enum SpeechEngine: String, CaseIterable {
        case macOS = "macOS say"
        case qwen3 = "Qwen3 TTS (MLX)"
    }

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

            // Engine + Parameters
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Engine").font(.caption).foregroundColor(.secondary)
                    Picker("Engine", selection: $engineMode) {
                        ForEach(SpeechEngine.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                    .onChange(of: engineMode) { _, _ in
                        audioPlayer = nil
                        outputInfo = ""
                    }
                }

                if engineMode == .macOS {
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
                }
                Spacer()
                Button("Generate Speech") {
                    generateSpeech()
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating)
            }
            .padding(.horizontal)

            // Qwen3 TTS settings
            if engineMode == .qwen3 {
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("Model Path").font(.caption).foregroundColor(.secondary)
                        Picker("Model", selection: $qwen3ModelPath) {
                            Text("Select a Qwen3 TTS model...").tag("")
                            ForEach(labModel.discoverQwen3TTSModels(), id: \.1) { (repoID, path) in
                                Text(repoID).tag(path)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 350)
                    }
                }
                .padding(.horizontal)

                if !qwen3ModelPath.isEmpty {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("Speaker (optional)").font(.caption).foregroundColor(.secondary)
                            TextField("e.g. Aiden", text: $qwen3Speaker)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                        }
                        VStack(alignment: .leading) {
                            Text("Instruct / Style (optional)").font(.caption).foregroundColor(.secondary)
                            TextField("e.g. Happy and energetic", text: $qwen3Instruct)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 250)
                        }
                    }
                    .padding(.horizontal)
                }
            }

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
            let info: String
            let audioData: Data?

            switch engineMode {
            case .macOS:
                (info, audioData) = await labModel.runSpeechGeneration(
                    text: inputText,
                    voiceName: voiceName,
                    rate: speakingRate
                )
            case .qwen3:
                guard !qwen3ModelPath.isEmpty else {
                    isGenerating = false
                    outputInfo = "Please select a Qwen3 TTS model first."
                    return
                }
                (info, audioData) = await labModel.runQwen3SpeechGeneration(
                    text: inputText,
                    modelPath: qwen3ModelPath,
                    speaker: qwen3Speaker.isEmpty ? nil : qwen3Speaker,
                    instruct: qwen3Instruct.isEmpty ? nil : qwen3Instruct,
                    language: "english"
                )
            }

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
