import SwiftUI
import ModelRegistry
import HuggingFaceCache
import MLX
import MLXBackend
import LlamaCppBackend
import StudioDomain
import StudioServices

@main
struct ModelLabApp: App {
    @StateObject private var labModel = ModelLabViewModel()

    init() {
        // Route MLX to CPU before any MLX lazy statics fire.
        // This avoids a Metal GPU conflict with llama.framework which also
        // claims Metal resources and can cause SIGABRT in mlx_default_gpu_stream_new.
        MLX.Device.setDefault(device: .cpu)
    }

    var body: some SwiftUI.Scene {
        WindowGroup {
            ModelLabContentView()
                .environmentObject(labModel)
                .frame(minWidth: 900, minHeight: 650)
                .onAppear {
                    Task { await labModel.initialize() }
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
    }
}

struct ModelLabContentView: View {
    @EnvironmentObject var labModel: ModelLabViewModel

    @State private var selectedTab = "models"

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            HStack(spacing: 0) {
                tabButton("Models", icon: "shippingbox", tab: "models")
                tabButton("LLM", icon: "brain", tab: "llm")
                tabButton("Speech", icon: "waveform", tab: "speech")
                tabButton("Voice", icon: "person.wave.2", tab: "voice")
                tabButton("Sound", icon: "music.note", tab: "sound")
                tabButton("Diagnostics", icon: "chart.xyaxis.line", tab: "diagnostics")
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .background(Color.secondary.opacity(0.05))

            Divider()

            // Content
            Group {
                switch selectedTab {
                case "models": ModelsScreen()
                case "llm": LLMScreen()
                case "speech": SpeechScreen()
                case "voice": VoiceScreen()
                case "sound": SoundScreen()
                case "diagnostics": DiagnosticsScreen()
                default: ModelsScreen()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func tabButton(_ label: String, icon: String, tab: String) -> some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                Text(label)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .background(
            selectedTab == tab
                ? Color.accentColor.opacity(0.1)
                : Color.clear
        )
        .overlay(alignment: .bottom) {
            if selectedTab == tab {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(height: 2)
            }
        }
    }
}

// MARK: - View Model

@MainActor
final class ModelLabViewModel: ObservableObject {
    @Published var cacheStatus: String = "Initializing..."
    @Published var diskUsage: String = "Calculating..."
    @Published var discoveredRepositories: [String] = []
    @Published var installedModels: [HuggingFaceModelSpecification] = []
    @Published var unrecognisedRepositories: [DiscoveredRepository] = []
    @Published var autoDiscoveredModels: [HuggingFaceModelSpecification] = []
    @Published var selectedModel: HuggingFaceModelSpecification?
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    @Published var llmOutput: String = ""
    @Published var isGenerating = false
    @Published var generationTokensPerSecond: Double = 0
    @Published var logs: [String] = []

    private let config = HuggingFaceCacheConfiguration()
    private lazy var scanner = CacheScanner(configuration: config)
    private var resolver: ModelResolver?
    private var mlxService: MLXLanguageModelService?
    private var llamaService: LlamaCppLanguageModelService?
    private var speechService: SaySpeechService?

    func initialize() async {
        let client = MockRepositoryClient(configuration: config)
        resolver = ModelResolver(configuration: config, repositoryClient: client)
        mlxService = MLXLanguageModelService(resolver: resolver!)
        llamaService = LlamaCppLanguageModelService(resolver: resolver!)
        speechService = SaySpeechService()

        await refreshCacheStatus()
    }

    func refreshCacheStatus() async {
        let usage = scanner.calculateDiskUsage()
        diskUsage = HuggingFaceCacheConfiguration.formatBytes(usage)
        discoveredRepositories = scanner.discoverRepositories()

        // CHECK CACHE: which bundled models are actually present?
        var installed: [HuggingFaceModelSpecification] = []
        for model in BundledModelCatalogue.allModels {
            let status = await scanner.inspect(model)
            switch status {
            case .cached, .partiallyCached:
                installed.append(model)
            default:
                break
            }
        }
        installedModels = installed

        // DISCOVER: find unrecognised repos not in bundled catalogue
        let details = scanner.discoverRepositoryDetails()
        unrecognisedRepositories = details.filter { !$0.matchesBundledModel }

        // AUTO-DISCOVER: build specifications from unrecognised repos
        autoDiscoveredModels = unrecognisedRepositories.compactMap { repo in
            HuggingFaceModelSpecification.from(discovered: repo)
        }

        cacheStatus = "\(discoveredRepositories.count) repos | \(installedModels.count) + \(autoDiscoveredModels.count) auto | \(diskUsage)"
        addLog("Cache refreshed: \(cacheStatus)")
        if !unrecognisedRepositories.isEmpty {
            addLog("Found \(unrecognisedRepositories.count) unrecognised repos: \(unrecognisedRepositories.map { $0.repositoryID }.joined(separator: ", "))")
        }
        if !autoDiscoveredModels.isEmpty {
            addLog("Auto-discovered \(autoDiscoveredModels.count) model(s): \(autoDiscoveredModels.map { $0.displayName }.joined(separator: ", "))")
        }
        if installedModels.isEmpty {
            addLog("No bundled models are installed yet.")
        } else {
            addLog("\(installedModels.count) bundled model(s) installed: \(installedModels.map { $0.displayName }.joined(separator: ", "))")
        }
    }

    func downloadModel(_ specification: HuggingFaceModelSpecification) async {
        guard let resolver else { return }
        isDownloading = true
        downloadProgress = 0
        addLog("Starting download: \(specification.displayName)")

        do {
            let _ = try await resolver.resolve(specification, policy: .online)
            addLog("Download complete: \(specification.displayName)")
            await refreshCacheStatus()
        } catch {
            addLog("Download failed: \(error.localizedDescription)")
        }

        isDownloading = false
    }

    func runLLMPrompt(_ prompt: String, backend: InferenceBackend, modelSpec: HuggingFaceModelSpecification?) async {
        isGenerating = true
        llmOutput = ""
        generationTokensPerSecond = 0
        addLog("Running LLM prompt (\(backend.displayName))...")

        let service: (any LanguageModelServing)?
        switch backend {
        case .mlx:
            service = mlxService
        case .llamaCpp:
            service = llamaService
        }

        guard let service else {
            addLog("ERROR: No service for backend \(backend.rawValue)")
            isGenerating = false
            return
        }

        // Load the model if we have a spec
        if let spec = modelSpec {
            if let llamaSvc = service as? LlamaCppLanguageModelService {
                do {
                    addLog("Loading model (llama.cpp): \(spec.displayName)...")
                    let loadStart = Date()
                    try await llamaSvc.load(spec)
                    let loadTime = Date().timeIntervalSince(loadStart)
                    addLog("Model loaded in \(String(format: "%.1f", loadTime))s")
                } catch {
                    addLog("ERROR loading model: \(error.localizedDescription)")
                    llmOutput = "Error loading model: \(error.localizedDescription)"
                    isGenerating = false
                    return
                }
            } else if let mlxSvc = service as? MLXLanguageModelService {
                do {
                    addLog("Loading model (MLX): \(spec.displayName)...")
                    let loadStart = Date()
                    try await mlxSvc.load(spec)
                    let loadTime = Date().timeIntervalSince(loadStart)
                    addLog("Model loaded in \(String(format: "%.1f", loadTime))s")
                } catch {
                    addLog("ERROR loading model: \(error.localizedDescription)")
                    llmOutput = "Error loading model: \(error.localizedDescription)"
                    isGenerating = false
                    return
                }
            }
        }

        let startTime = Date()
        var tokenCount = 0

        do {
            let stream = try await service.generate(
                prompt: prompt,
                schemaJSON: nil,
                temperature: 0.7,
                seed: 42
            )
            for try await token in stream {
                llmOutput += token
                tokenCount += 1
            }

            let elapsed = Date().timeIntervalSince(startTime)
            generationTokensPerSecond = Double(tokenCount) / max(elapsed, 0.001)
            addLog("LLM complete: \(tokenCount) tokens in \(String(format: "%.1f", elapsed))s (\(String(format: "%.1f", generationTokensPerSecond)) tok/s)")

            // Also read diagnostics from both backends
            if let llamaSvc = service as? LlamaCppLanguageModelService {
                let diag = await llamaSvc.diagnostics
                addLog("Diagnostics (llama.cpp): load=\(String(format: "%.1f", diag.loadDuration))s, tok/s=\(String(format: "%.1f", diag.lastTokensPerSecond))")
            }
            if let mlxSvc = service as? MLXLanguageModelService {
                let diag = await mlxSvc.diagnostics
                addLog("Diagnostics (MLX): load=\(String(format: "%.1f", diag.loadDuration))s, tok/s=\(String(format: "%.1f", diag.lastTokensPerSecond))")
            }
        } catch {
            llmOutput = "Error: \(error.localizedDescription)"
            addLog("LLM error: \(error.localizedDescription)")
        }

        isGenerating = false
    }

    func addLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logs.append("[\(timestamp)] \(message)")
    }

    func runSpeechGeneration(text: String, voiceName: String = "Samantha", rate: Double = 1.0) async -> (String, Data?) {
        guard let service = speechService else {
            addLog("ERROR: No speech service available")
            return ("No speech service available.", nil)
        }
        addLog("Generating speech (voice: \(voiceName), rate: \(String(format: "%.1f", rate))x)...")
        let startTime = Date()
        do {
            let result = try await service.generateSpeech(
                text: text,
                voiceName: voiceName,
                rate: rate
            )
            let elapsed = Date().timeIntervalSince(startTime)
            let rtf = result.duration > 0 ? elapsed / result.duration : 0
            addLog("Speech generated: \(String(format: "%.2f", result.duration))s audio in \(String(format: "%.1f", elapsed))s (RTF: \(String(format: "%.2f", rtf))x)")
            let info = """
            --- Speech Generation Results ---
            Text length: \(text.count) chars
            Word count: \(text.split(separator: " ").count)
            Voice: \(voiceName)
            Rate: \(String(format: "%.1f", rate))x
            ---
            Duration: \(String(format: "%.2f", result.duration))s
            Sample rate: \(result.sampleRate) Hz
            Channels: \(result.channelCount)
            Audio size: \(result.audioData.count) bytes
            Generation time: \(String(format: "%.1f", elapsed))s (RTF: \(String(format: "%.2f", rtf))x)
            ---
            Status: Success (macOS say)
            """
            return (info, result.audioData)
        } catch {
            addLog("Speech generation failed: \(error.localizedDescription)")
            let errorInfo = """
            --- Speech Generation Results ---
            Status: FAILED
            Error: \(error.localizedDescription)
            """
            return (errorInfo, nil)
        }
    }
}
