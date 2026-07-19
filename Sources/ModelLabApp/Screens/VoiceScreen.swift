import SwiftUI
import AVFoundation
import HuggingFaceCache

struct VoiceScreen: View {
    @EnvironmentObject var labModel: ModelLabViewModel
    @State private var description = "Warm, authoritative British male narrator. Clear enunciation, natural pacing."
    @State private var sampleText = "The package arrived on a Tuesday, wrapped in brown paper and silence."
    @State private var speaker = "aiden"
    @State private var isGenerating = false
    @State private var outputInfo = ""
    @State private var audioPlayer: AVAudioPlayer?
    @State private var qwen3ModelPath = ""
    @State private var useQwen3 = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Voice Profile")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // Engine picker
            HStack(spacing: 12) {
                Text("Engine").font(.caption).foregroundColor(.secondary)
                Picker("Engine", selection: $useQwen3) {
                    Text("macOS say").tag(false)
                    Text("Qwen3 TTS CustomVoice").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 300)

                if useQwen3 {
                    let allModels = labModel.discoverQwen3TTSModels()
                    Picker("Model", selection: $qwen3ModelPath) {
                        Text("Select model...").tag("")
                        ForEach(allModels, id: \.1) { (repo, path) in
                            Text(repo).tag(path)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 350)
                }
            }
            .padding(.horizontal)

            // Voice parameters
            ScrollView {
                VStack(spacing: 12) {
                    paramField("Voice Description", text: $description, lines: 2)
                    paramField("Sample Text", text: $sampleText, lines: 2)

                    HStack(spacing: 20) {
                        if !useQwen3 {
                            VStack(alignment: .leading) {
                                Text("Voice").font(.caption).foregroundColor(.secondary)
                                Picker("Voice", selection: $speaker) {
                                    ForEach(["Samantha", "Daniel", "Karen", "Fiona", "Moira", "Veena", "Alex"], id: \.self) {
                                        Text($0).tag($0)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 180)
                            }
                        } else if !qwen3ModelPath.isEmpty {
                            VStack(alignment: .leading) {
                                Text("Base Speaker").font(.caption).foregroundColor(.secondary)
                                Picker("Speaker", selection: $speaker) {
                                    Text("default").tag("")
                                    ForEach(["aiden", "dylan", "eric", "ono_anna", "ryan", "serena", "sohee", "uncle_fu", "vivian"], id: \.self) {
                                        Text($0).tag($0)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(width: 180)
                            }
                        }
                        Spacer()
                        Button("Generate") { generateVoice() }
                            .buttonStyle(.borderedProminent)
                            .disabled(isGenerating)
                    }
                }
                .padding(.horizontal)
            }

            Divider()

            // Output + playback
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Output")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Spacer()
                    if audioPlayer != nil {
                        HStack(spacing: 8) {
                            Button(action: { audioPlayer?.currentTime = 0; audioPlayer?.play() }) {
                                Label("Play", systemImage: "play.fill")
                            }
                            .buttonStyle(.bordered).controlSize(.small).tint(.green)
                            Button(action: { audioPlayer?.stop() }) {
                                Label("Stop", systemImage: "stop.fill")
                            }
                            .buttonStyle(.bordered).controlSize(.small).tint(.red)
                        }
                    }
                }
                ScrollView {
                    if outputInfo.isEmpty {
                        Text("Generated audio info will appear here...")
                            .foregroundColor(.secondary).padding()
                    } else {
                        Text(outputInfo).font(.body.monospaced())
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.top)
    }

    private func paramField(_ label: String, text: Binding<String>, lines: Int = 1) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.caption).foregroundColor(.secondary)
            if lines > 1 {
                TextEditor(text: text).font(.body).frame(minHeight: CGFloat(lines * 30)).padding(2)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
            } else {
                TextField("", text: text).textFieldStyle(.roundedBorder)
            }
        }
    }

    private func generateVoice() {
        guard !sampleText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isGenerating = true
        outputInfo = ""
        audioPlayer = nil

        Task {
            let info: String
            let audioData: Data?

            if useQwen3 && !qwen3ModelPath.isEmpty {
                let instruct = "\(description). Accent: \(description). Tone: \(description)."
                (info, audioData) = await labModel.runQwen3SpeechGeneration(
                    text: sampleText,
                    modelPath: qwen3ModelPath,
                    speaker: speaker.isEmpty ? nil : speaker,
                    instruct: instruct,
                    language: "english"
                )
            } else {
                (info, audioData) = await labModel.runSpeechGeneration(
                    text: sampleText,
                    voiceName: speaker,
                    rate: 1.0
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
}
