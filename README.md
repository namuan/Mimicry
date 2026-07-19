# Mimicry

A native macOS audiobook production studio built in Swift + SwiftUI. Imports EPUBs, analyses text with local LLMs, generates character voices, designs soundscapes, and exports finished audiobooks — all running locally on Apple Silicon.

Two companion applications:

- **AudiobookStudio** — the full mocked production workflow (Import → Export)
- **AudiobookModelLab** — a model laboratory for testing LLM, speech, and audio models locally

## Requirements

- macOS 14 or later
- Apple Silicon (M1/M2/M3/M4)
- 16 GB+ RAM recommended
- Xcode Command Line Tools (`xcode-select --install`)
- Optional: [Hugging Face CLI](https://huggingface.co/docs/huggingface_hub) to pre-populate model cache

## Quick Start

```bash
# Clone and build everything
make bootstrap
make app

# Run the mocked studio
make run-studio

# Run the model laboratory (real LLM + speech)
make run-model-lab

# Run tests
make test
```

## Build Targets

| Command              | Description                                          |
| -------------------- | ---------------------------------------------------- |
| `make bootstrap`     | Verify Swift toolchain is available                  |
| `make studio`        | Release build of AudiobookStudio                     |
| `make model-lab`     | Release build of AudiobookModelLab                   |
| `make test`          | Run all test suites                                  |
| `make app`           | Produce both `.app` bundles in `.build/dist/`        |
| `make run-studio`    | Incremental debug build + open AudiobookStudio       |
| `make run-model-lab` | Incremental debug build + open AudiobookModelLab     |
| `make verify`        | Validate `.app` bundle structure, signing, and plist |
| `make clean`         | Remove build artifacts                               |

Output goes to `.build/dist/`:

- `.build/dist/AudiobookStudio.app`
- `.build/dist/AudiobookModelLab.app`

No Xcode project is required. Everything is driven by `Package.swift`.

## Architecture

```
Sources/
├── StudioApp/          AudiobookStudio — SwiftUI app, 9 workflow stages
├── ModelLabApp/        AudiobookModelLab — model testing lab, 6 tabs
├── StudioDomain/       16 domain types (Project, Chapter, Scene, etc.)
├── StudioServices/     9 service protocols (EPUB importing, LLM, TTS, etc.)
├── StudioMocks/        11 mock implementations + sample project data
├── StudioPersistence/  Placeholder for SQLite layer (future)
├── ModelRegistry/      Model purposes, specifications, bundled catalogue
├── HuggingFaceCache/   Cache resolution, scanning, model resolver, auth
├── MLXBackend/         MLX Swift + MLX Swift LM integration
├── LlamaCppBackend/    llama.cpp via LocalLLMClient (direct library, no server)
└── LlamaSmokeTest/     Quick smoke test for GGUF model loading
Tests/
├── StudioDomainTests/   Domain model logic
├── StudioMocksTests/    Mock service contracts
└── StudioModelsTests/   Model registry and cache types
```

## Workflow stages (AudiobookStudio)

```
Import → Structure → Characters → Script → Voices → Sound Design → Generate → Review → Export
```

Each stage is a full SwiftUI screen with mock data. The sample project ("The Shadow Protocol") includes 3 chapters, 10 scenes, 7 characters, and deliberately awkward edge cases (unnamed characters, aliases, unresolved dialogue, wrong scene boundaries).

## Model backends (AudiobookModelLab)

| Backend       | Engine                          | Format      | Status                                                    |
| ------------- | ------------------------------- | ----------- | --------------------------------------------------------- |
| **llama.cpp** | `LocalLLMClient` (direct C API) | GGUF        | Working — ~50–70 tok/s on Metal GPU                       |
| **MLX**       | `mlx-swift` + `mlx-swift-lm`    | safetensors | Working — CPU mode (avoids Metal conflict with llama.cpp) |
| **Speech**    | macOS `say`                     | AIFF        | Working — system TTS voices                               |

Models are loaded from the standard Hugging Face cache (`~/.cache/huggingface/hub/`). The app auto-discovers cached models, infers their purpose and backend, and presents them alongside the bundled catalogue.

## Hugging Face cache policy

The app follows the standard Hugging Face cache layout and respects `HF_HUB_CACHE` / `HF_HOME` environment variables. Model weights live in the cache, not in the project database or app bundle. Projects store only model references (repository ID, revision, backend, parameters).

```
Cache-only mode available — zero network requests.
```

## License

[MIT](LICENSE)
