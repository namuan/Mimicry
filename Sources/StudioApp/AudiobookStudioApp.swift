import SwiftUI
import StudioDomain
import StudioMocks

@main
struct AudiobookStudioApp: App {
    @StateObject private var model = StudioApplicationModel(
        repository: MockProjectRepository(),
        epubImporter: MockEPUBImporter(),
        bookAnalyzer: MockBookAnalyzer(),
        languageModel: MockLanguageModelService(),
        voiceGenerator: MockVoiceGenerator(),
        speechGenerator: MockSpeechGenerator(),
        soundtrackGenerator: MockSoundtrackGenerator(),
        audioMixer: MockAudioMixer(),
        exporter: MockExporter()
    )

    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .frame(minWidth: 1100, minHeight: 750)
                .onAppear {
                    Task { await model.loadSampleProject() }
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentMinSize)
    }
}

struct ContentView: View {
    @EnvironmentObject var model: StudioApplicationModel

    var body: some View {
        VStack(spacing: 0) {
            WorkflowBarView()
                .padding(.horizontal)
                .padding(.top, 8)

            Divider()
                .padding(.top, 4)

            if let project = model.projectViewState {
                StageContentView(stage: model.selectedStage, project: project)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack {
                    Spacer()
                    ProgressView("Loading project...")
                        .progressViewStyle(.circular)
                        .scaleEffect(1.5)
                    Spacer()
                }
            }
        }
    }
}
