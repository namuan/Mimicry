import Testing
import Foundation
@testable import ModelRegistry

@Suite struct ModelPurposeTests {

    @Test func allPurposesPresent() {
        #expect(ModelPurpose.allCases.count == 7)
    }

    @Test func purposeDescriptions() {
        for purpose in ModelPurpose.allCases {
            #expect(!purpose.description.isEmpty)
        }
    }
}

@Suite struct InferenceBackendTests {

    @Test func allBackendsPresent() {
        #expect(InferenceBackend.allCases.count == 2)
    }

    @Test func backendDisplayNames() {
        #expect(InferenceBackend.mlx.displayName == "MLX Swift")
        #expect(InferenceBackend.llamaCpp.displayName == "llama.cpp")
    }

    @Test func backendExpectedExtensions() {
        #expect(InferenceBackend.mlx.expectedExtensions.contains("safetensors"))
        #expect(InferenceBackend.llamaCpp.expectedExtensions.contains("gguf"))
    }
}

@Suite struct ModelIdentityTests {

    @Test func identityCreation() {
        let identity = ModelIdentity(
            repositoryID: "test/repo",
            revision: "abc123",
            backend: .mlx,
            requiredFiles: [RequiredModelFile(path: "model.safetensors")]
        )
        #expect(identity.repositoryID == "test/repo")
        #expect(identity.revision == "abc123")
        #expect(identity.backend == .mlx)
    }
}

@Suite struct HuggingFaceModelSpecificationTests {

    @Test func specificationCreation() {
        let spec = HuggingFaceModelSpecification(
            id: "test-model",
            displayName: "Test Model",
            purpose: .sceneDetection,
            backend: .mlx,
            repositoryID: "test/repo",
            revision: "main",
            requiredFiles: [RequiredModelFile(path: "config.json")],
            contextLength: 4096,
            estimatedMemoryBytes: 4_000_000_000,
            licenseIdentifier: "Apache-2.0",
            gated: false
        )
        #expect(spec.id == "test-model")
        #expect(spec.displayName == "Test Model")
        #expect(spec.purpose == .sceneDetection)
        #expect(spec.backend == .mlx)
        #expect(spec.gated == false)
    }

    @Test func identityFromSpecification() {
        let spec = HuggingFaceModelSpecification(
            id: "test",
            displayName: "Test",
            purpose: .speech,
            backend: .llamaCpp,
            repositoryID: "publisher/model",
            revision: "v1.0",
            requiredFiles: [RequiredModelFile(path: "model.gguf")]
        )
        let identity = spec.identity
        #expect(identity.repositoryID == "publisher/model")
        #expect(identity.revision == "v1.0")
        #expect(identity.backend == .llamaCpp)
    }
}

@Suite struct BundledModelCatalogueTests {

    @Test func allModelsNotEmpty() {
        #expect(!BundledModelCatalogue.allModels.isEmpty)
    }

    @Test func modelsByPurpose() {
        let sceneModels = BundledModelCatalogue.models(for: .sceneDetection)
        #expect(sceneModels.count >= 2) // At least MLX and llama.cpp variants

        let speechModels = BundledModelCatalogue.models(for: .speech)
        #expect(speechModels.count >= 1)
    }

    @Test func modelsByBackend() {
        let mlxModels = BundledModelCatalogue.models(for: .mlx)
        #expect(!mlxModels.isEmpty)

        let llamaModels = BundledModelCatalogue.models(for: .llamaCpp)
        #expect(!llamaModels.isEmpty)
    }

    @Test func modelByID() {
        let model = BundledModelCatalogue.model(id: "scene-detection-mlx")
        #expect(model != nil)
        #expect(model?.purpose == .sceneDetection)
        #expect(model?.backend == .mlx)
    }

    @Test func nonexistentModelID() {
        let model = BundledModelCatalogue.model(id: "nonexistent-model")
        #expect(model == nil)
    }
}

@Suite struct ModelDownloadProgressTests {

    @Test func progressFraction() {
        let progress = ModelDownloadProgress(
            bytesDownloaded: 50_000_000,
            totalBytes: 100_000_000,
            filesCompleted: 1,
            totalFiles: 2
        )
        #expect(progress.fractionComplete == 0.5)
    }

    @Test func zeroByteProgress() {
        let progress = ModelDownloadProgress()
        #expect(progress.fractionComplete == 0)
        #expect(progress.bytesDownloaded == 0)
    }
}
