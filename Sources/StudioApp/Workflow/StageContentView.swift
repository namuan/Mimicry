import SwiftUI
import StudioDomain

/// Routes to the appropriate screen based on the selected workflow stage.
struct StageContentView: View {
    let stage: WorkflowStage
    let project: ProjectViewState

    var body: some View {
        Group {
            switch stage {
            case .import:
                ImportScreen(project: project)
            case .structure:
                StructureScreen(project: project)
            case .characters:
                CharactersScreen(project: project)
            case .script:
                ScriptScreen(project: project)
            case .voices:
                VoicesScreen(project: project)
            case .soundDesign:
                SoundDesignScreen(project: project)
            case .generate:
                GenerateScreen(project: project)
            case .review:
                ReviewScreen(project: project)
            case .export:
                ExportScreen(project: project)
            }
        }
    }
}
