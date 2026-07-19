import SwiftUI

struct VoiceScreen: View {
    @State private var description = "Warm, authoritative British male narrator. Clear enunciation, natural pacing."
    @State private var accent = "British RP"
    @State private var ageRange = "45-55"
    @State private var tone = "Warm, authoritative"
    @State private var sampleText = "The package arrived on a Tuesday, wrapped in brown paper and silence."
    @State private var seed = "42"
    @State private var isGenerating = false
    @State private var outputInfo = ""

    var body: some View {
        VStack(spacing: 12) {
            Text("Voice Profile Experiment")
                .font(.title2)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

            // Parameters form
            ScrollView {
                VStack(spacing: 12) {
                    paramField("Description", text: $description, lines: 3)
                    paramField("Accent", text: $accent)
                    paramField("Age Range", text: $ageRange)
                    paramField("Tone", text: $tone)
                    paramField("Sample Text", text: $sampleText, lines: 2)
                    paramField("Seed", text: $seed)

                    HStack {
                        Spacer()
                        Button("Generate Voice Profile") {
                            generateVoice()
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
                        Text("Generated voice profile info will appear here...")
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

    private func paramField(_ label: String, text: Binding<String>, lines: Int = 1) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            if lines > 1 {
                TextEditor(text: text)
                    .font(.body)
                    .frame(minHeight: CGFloat(lines * 30))
                    .padding(2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            } else {
                TextField("", text: text)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private func generateVoice() {
        isGenerating = true
        Task {
            try? await Task.sleep(for: .seconds(2.0))
            outputInfo = """
            --- Voice Profile Generation Results ---
            Name: Generated Voice
            Description: \(description)
            Accent: \(accent)
            Age Range: \(ageRange)
            Tone: \(tone)
            Sample Text: "\(sampleText)"
            Seed: \(seed)
            ---
            Preview audio: 48000 bytes (2.0s @ 24kHz 16-bit mono)
            Reproducibility metadata: seed=\(seed), model=voice-design-v1
            Status: Success (mock)
            """
            isGenerating = false
        }
    }
}
