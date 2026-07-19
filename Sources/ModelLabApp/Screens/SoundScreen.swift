import SwiftUI

struct SoundScreen: View {
    @State private var sceneSummary = "Elena receives a mysterious package at her Vienna apartment. Tension builds."
    @State private var location = "Vienna apartment, dusk"
    @State private var mood = "Tense, foreboding"
    @State private var musicPrompt = "Subdued, pulsing tension. Low strings and distant electronic textures."
    @State private var ambiencePrompt = "Quiet apartment at dusk. Distant street traffic, occasional tram bell."
    @State private var requestedDuration: Double = 30.0
    @State private var isGenerating = false
    @State private var outputInfo = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("Scene Audio Experiment")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            ScrollView {
                VStack(spacing: 12) {
                    // Scene info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Scene Context").font(.headline).foregroundColor(.secondary)
                        TextField("Scene summary", text: $sceneSummary)
                            .textFieldStyle(.roundedBorder)
                        TextField("Location", text: $location)
                            .textFieldStyle(.roundedBorder)
                        TextField("Mood", text: $mood)
                            .textFieldStyle(.roundedBorder)
                    }

                    // Prompts
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Music Prompt").font(.caption).foregroundColor(.secondary)
                        TextEditor(text: $musicPrompt)
                            .font(.body)
                            .frame(minHeight: 50)
                            .padding(2)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Ambience Prompt").font(.caption).foregroundColor(.secondary)
                        TextEditor(text: $ambiencePrompt)
                            .font(.body)
                            .frame(minHeight: 50)
                            .padding(2)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.3), lineWidth: 1))
                    }

                    // Duration
                    HStack {
                        Text("Requested Duration: \(Int(requestedDuration))s")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Slider(value: $requestedDuration, in: 5...120, step: 5)
                    }

                    HStack {
                        Spacer()
                        Button("Generate Scene Audio") {
                            generateSceneAudio()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isGenerating)
                    }
                }
                .padding(.horizontal)
            }

            Divider()

            // Output
            VStack(alignment: .leading, spacing: 8) {
                Text("Output")
                    .font(.headline)
                    .foregroundColor(.secondary)

                ScrollView {
                    if outputInfo.isEmpty {
                        Text("Generated audio info will appear here...")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        Text(outputInfo)
                            .font(.body.monospaced())
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.top)
    }

    private func generateSceneAudio() {
        isGenerating = true
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            outputInfo = """
            --- Scene Audio Generation Results ---
            Music prompt: \(musicPrompt)
            Ambience prompt: \(ambiencePrompt)
            Requested duration: \(Int(requestedDuration))s
            ---
            Music output: \(Int(requestedDuration) * 48000) bytes (WAV, 24kHz mono)
            Ambience output: \(Int(requestedDuration) * 48000) bytes (WAV, 24kHz mono)
            Music loopable: true
            Ambience loopable: true
            Status: Success (mock)
            """
            isGenerating = false
        }
    }
}
