import SwiftUI
import ModelRegistry

struct LLMScreen: View {
    @EnvironmentObject var labModel: ModelLabViewModel
    @State private var prompt: String = "Given this scene and character list:\n\n1. Identify scene characters.\n2. Reuse existing character IDs.\n3. Identify dialogue blocks and speakers.\n4. Return strict JSON."
    @State private var temperature: Double = 0.7
    @State private var selectedBackend: InferenceBackend = .mlx
    @State private var selectedModelSpec: HuggingFaceModelSpecification?

    var body: some View {
        VStack(spacing: 0) {
            // Controls
            HStack(spacing: 16) {
                Text("LLM Experiment")
                    .font(.title2)
                    .fontWeight(.bold)

                Picker("Backend", selection: $selectedBackend) {
                    ForEach(InferenceBackend.allCases, id: \.self) { backend in
                        Text(backend.displayName).tag(backend)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 250)

                HStack {
                    Text("Temp: \(String(format: "%.1f", temperature))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Slider(value: $temperature, in: 0...2, step: 0.1)
                        .frame(width: 150)
                }

                Spacer()

                if labModel.isGenerating {
                    Button("Cancel") { }
                        .buttonStyle(.bordered)
                        .tint(.red)
                        .controlSize(.small)
                } else {
                    Button("Generate") {
                        Task { await labModel.runLLMPrompt(prompt, backend: selectedBackend, modelSpec: selectedModelSpec) }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }

                if labModel.generationTokensPerSecond > 0 {
                    Text("\(String(format: "%.1f", labModel.generationTokensPerSecond)) tok/s")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
            .padding()

            // Model selection for real inference
            if !labModel.autoDiscoveredModels.isEmpty {
                Picker("Model", selection: $selectedModelSpec) {
                    Text("Select a model...").tag(nil as HuggingFaceModelSpecification?)
                    ForEach(labModel.autoDiscoveredModels) { model in
                        Text(model.displayName).tag(model as HuggingFaceModelSpecification?)
                    }
                    ForEach(labModel.installedModels) { model in
                        Text("\(model.displayName) (bundled)").tag(model as HuggingFaceModelSpecification?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 300)
            }

            Divider()

            // Prompt and output
            HSplitView {
                // Prompt
                VStack(alignment: .leading, spacing: 8) {
                    Text("Prompt")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    TextEditor(text: $prompt)
                        .font(.body.monospaced())
                        .padding(4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
                .padding()

                // Output
                VStack(alignment: .leading, spacing: 8) {
                    Text("Output")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    ScrollView {
                        if labModel.isGenerating {
                            Text(labModel.llmOutput)
                                .font(.body.monospaced())
                                .frame(maxWidth: .infinity, alignment: .leading)
                            ProgressView()
                                .scaleEffect(0.7)
                        } else if labModel.llmOutput.isEmpty {
                            Text("Output will appear here...")
                                .foregroundColor(.secondary)
                                .padding()
                        } else {
                            Text(labModel.llmOutput)
                                .font(.body.monospaced())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.secondary.opacity(0.03)))
                }
                .padding()
            }
        }
        .onChange(of: selectedModelSpec) { _, newModel in
            if let model = newModel {
                selectedBackend = model.backend
            }
        }
    }
}
