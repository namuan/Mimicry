// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "AudiobookStudio",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "AudiobookStudio", targets: ["StudioApp"]),
        .executable(name: "AudiobookModelLab", targets: ["ModelLabApp"]),
        .executable(name: "LlamaSmokeTest", targets: ["LlamaSmokeTest"])
    ],
    dependencies: [
        .package(url: "https://github.com/ml-explore/mlx-swift", branch: "main"),
        .package(url: "https://github.com/ml-explore/mlx-swift-lm", branch: "main"),
        .package(path: "vendor/LocalLLMClient"),
        .package(url: "https://github.com/huggingface/swift-transformers", from: "1.3.0")
    ],
    targets: [
        // ── Libraries ──────────────────────────────────────────

        .target(
            name: "StudioDomain",
            path: "Sources/StudioDomain"
        ),

        .target(
            name: "StudioServices",
            dependencies: ["StudioDomain"],
            path: "Sources/StudioServices"
        ),

        .target(
            name: "StudioMocks",
            dependencies: ["StudioDomain", "StudioServices"],
            path: "Sources/StudioMocks"
        ),

        .target(
            name: "StudioPersistence",
            dependencies: ["StudioDomain", "StudioServices"],
            path: "Sources/StudioPersistence"
        ),

        .target(
            name: "ModelRegistry",
            path: "Sources/ModelRegistry"
        ),

        .target(
            name: "HuggingFaceCache",
            dependencies: ["ModelRegistry"],
            path: "Sources/HuggingFaceCache"
        ),

        .target(
            name: "MLXBackend",
            dependencies: [
                "ModelRegistry",
                "HuggingFaceCache",
                "StudioServices",
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "Tokenizers", package: "swift-transformers"),
            ],
            path: "Sources/MLXBackend"
        ),

        .target(
            name: "LlamaCppBackend",
            dependencies: [
                "ModelRegistry",
                "HuggingFaceCache",
                "StudioServices",
                .product(name: "LocalLLMClient", package: "LocalLLMClient"),
                .product(name: "LocalLLMClientLlama", package: "LocalLLMClient"),
            ],
            path: "Sources/LlamaCppBackend",
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),

        // ── Executables ────────────────────────────────────────

        .executableTarget(
            name: "StudioApp",
            dependencies: [
                "StudioDomain",
                "StudioServices",
                "StudioMocks",
                "StudioPersistence"
            ],
            path: "Sources/StudioApp"
        ),

        .executableTarget(
            name: "ModelLabApp",
            dependencies: [
                "ModelRegistry",
                "HuggingFaceCache",
                "MLXBackend",
                "LlamaCppBackend"
            ],
            path: "Sources/ModelLabApp",
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),

        // ── Smoke Test ─────────────────────────────────────────

        .executableTarget(
            name: "MLXSmokeTest",
            dependencies: [
                "HuggingFaceCache",
                .product(name: "MLX", package: "mlx-swift"),
                .product(name: "MLXLLM", package: "mlx-swift-lm"),
                .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
                .product(name: "Tokenizers", package: "swift-transformers"),
            ],
            path: "Sources/MLXSmokeTest"
        ),

        // ── Tests ──────────────────────────────────────────────

        .testTarget(
            name: "StudioDomainTests",
            dependencies: ["StudioDomain"],
            path: "Tests/StudioDomainTests"
        ),

        .testTarget(
            name: "StudioMocksTests",
            dependencies: ["StudioMocks"],
            path: "Tests/StudioMocksTests"
        ),

        .testTarget(
            name: "StudioModelsTests",
            dependencies: ["ModelRegistry"],
            path: "Tests/StudioModelsTests"
        ),

        // ── Llama C++ Smoke Test ───────────────────────────────

        .executableTarget(
            name: "LlamaSmokeTest",
            dependencies: [
                .product(name: "LocalLLMClient", package: "LocalLLMClient"),
                .product(name: "LocalLLMClientLlama", package: "LocalLLMClient"),
            ],
            path: "Sources/LlamaSmokeTest",
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
