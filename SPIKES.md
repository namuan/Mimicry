Your two-spike approach is sensible. It separates validating the product workflow from validating the technically risky model integrations.

One policy decision is still needed: **where downloaded model weights live**. They can be several gigabytes and are not project-specific media. I recommend treating them as application runtime data stored in the standard macOS Application Support or Caches directory—not inside every project database. Projects should store the model identifier, version, parameters, prompts, seeds, and generated results. MLX Swift is designed for running models on Apple silicon, while MLX Swift LM provides Swift LLM implementations and model-loading support. ([GitHub][1])

# Technical baseline

Use:

* Swift
* SwiftUI for the application interface
* Swift Package Manager for dependencies and builds
* SQLite for project persistence
* XCTest or Swift Testing for automated tests
* A shell script or Makefile for producing the `.app`
* No storyboards, Interface Builder, or Xcode UI configuration

SwiftUI is Apple’s native declarative UI framework, and SwiftPM supports building executables, managing dependencies, testing, and bundling package resources. ([Apple Developer][2])

The development workflow would be:

```bash
make run
make test
make app
make clean
```

The final command produces:

```text
.build/dist/AudiobookStudio.app
```

It can then be opened with:

```bash
open .build/dist/AudiobookStudio.app
```

For the MVP, the build should initially target Apple silicon only. MLX itself is oriented around Apple silicon, and postponing an Intel universal binary removes unnecessary complexity. Apple documents universal binaries separately for applications that later need both architectures. ([GitHub][1])

---

# Spike 1: Complete mocked application

## Objective

Build the complete user experience before implementing EPUB parsing, SQLite persistence, or model inference.

The result should look and behave like the intended application, but all content and operations are supplied by deterministic mock services.

This spike validates:

* Workflow stages
* Navigation
* Editing interactions
* Terminology
* Information density
* Review and correction flows
* User understanding
* Long-running job presentation
* Error and stale-state presentation

## Workflow bar

The application always displays the stages at the top:

```text
Import
  →
Structure
  →
Characters
  →
Script
  →
Voices
  →
Sound Design
  →
Generate
  →
Review
  →
Export
```

Each stage supports:

* Not started
* Available
* In progress
* Needs review
* Complete
* Out of date
* Failed

Users can move between available stages without losing their work.

The mocked application should demonstrate dependency invalidation. For example, moving a scene boundary should mark the affected character analysis, script attribution, generated speech, and scene mix as out of date.

## Mock project

Ship the spike with a representative sample project containing:

* 3 chapters
* 8–12 scenes
* One narrator
* 5–7 characters
* Clear and ambiguous dialogue
* Duplicate-character candidates
* Voice candidates
* Background audio prompts
* Generated-looking audio waveforms
* Failed and stale generation jobs
* Review issues
* Export validation warnings

The mock book should deliberately include awkward cases:

* A narrator who also speaks
* An alias
* An unnamed character such as “the guard”
* Dialogue with no explicit speaker
* A character speaking from another room
* Internal thought represented as narration
* A scene boundary that is intentionally wrong

## Stage-level UI

### Import

Display:

* EPUB selection
* Cover
* Title and author metadata
* Table of contents
* Included and excluded sections
* Simulated import progress

No real EPUB processing is required in this spike.

### Structure

Display:

* Chapter and scene navigator
* Chapter text with scene boundaries
* Scene summary and metadata
* Split, merge, rename, and move-boundary actions
* AI confidence and review flags

### Characters

Display:

* Project-wide character list
* Character aliases
* Scene appearances
* Duplicate-character suggestions
* Merge and split operations
* Narrator designation

### Script

Display every block inside the selected scene:

```text
Narrator
The corridor was completely dark.

Elena
“We shouldn’t be here.”

Marcus
“You said that ten minutes ago.”
```

Support:

* Change speaker
* Change narration/dialogue type
* Split block
* Merge blocks
* Edit production text
* Exclude block
* Restore source text
* Filter unresolved speakers

### Voices

Display:

* Character cards
* Assigned voice
* Voice descriptions
* Several mocked voice candidates
* Preview playback
* Assign, remove, and regenerate actions
* Narrator voice

Use bundled sample audio or generated test tones for playback. The UI should not depend on a real audio model yet.

### Sound Design

Display:

* Scene metadata
* Background-music prompt
* Ambience prompt
* Music and ambience controls
* Volume
* Fade duration
* Dialogue ducking
* Mock waveform
* Generate and regenerate actions

### Generate

Display:

* Scope selection: line, scene, chapter, or book
* Estimated duration
* Estimated cost or compute use
* Queue
* Progress
* Cancellation
* Failure and retry
* Asset reuse
* Generation logs suitable for normal users

### Review

Display a unified issue queue:

* Uncertain speaker
* Possible duplicate character
* Missing voice
* Missing audio
* Stale dialogue
* Failed generation
* Abrupt scene transition
* Export validation error

Selecting an issue should navigate to the relevant stage and entity.

### Export

Display:

* Format
* Output directory
* Chapter naming
* Cover and metadata
* Validation results
* Mock export progress
* Reveal in Finder action

## Mock service boundaries

The mock UI should not call static arrays directly. Define protocols that later implementations can replace:

```swift
protocol ProjectRepository
protocol EPUBImporting
protocol BookAnalyzing
protocol LanguageModelServing
protocol VoiceGenerating
protocol SpeechGenerating
protocol SoundtrackGenerating
protocol AudioMixing
protocol Exporting
```

Create mock implementations:

```swift
MockProjectRepository
MockEPUBImporter
MockBookAnalyzer
MockLanguageModelService
MockVoiceGenerator
MockSpeechGenerator
MockSoundtrackGenerator
MockAudioMixer
MockExporter
```

This keeps the UI spike useful rather than disposable.

## State management

Use one explicit application model:

```swift
@MainActor
final class StudioApplicationModel: ObservableObject {
    var project: ProjectViewState?
    var selectedStage: WorkflowStage
    var selectedChapterID: Chapter.ID?
    var selectedSceneID: Scene.ID?
    var selectedBlockID: ScriptBlock.ID?
    var activeJobs: [JobViewState]
    var reviewIssues: [ReviewIssueViewState]
}
```

The UI should consume presentation models rather than database records or model-provider objects.

## Spike 1 completion criteria

The spike is complete when:

1. Every workflow stage is navigable.
2. A user can complete the entire mocked journey from import through export.
3. Backward edits correctly produce mocked stale states.
4. Review issues deep-link to the affected item.
5. Voice and scene previews play bundled audio.
6. Loading, empty, error, cancellation, and retry states are represented.
7. The application can be built entirely from Terminal.
8. `make app` produces a Finder-openable `.app`.
9. No Xcode project or workspace is required.
10. No production model or EPUB dependency is present.

---

# Spike 2: Model-loading laboratory

## Objective

Build a separate minimal application that proves Swift can load and execute the intended LLM and audio model technologies.

This should not initially be integrated into the studio UI.

The biggest mistake would be connecting experimental model code directly to the finished UI before understanding its memory, packaging, concurrency, and latency characteristics.

## Laboratory interface

Use a simple SwiftUI window with tabs:

```text
Models
LLM
Speech
Voice
Sound
Diagnostics
```

This is a technical tool rather than a polished product experience.

## Model manager

The laboratory should support:

* List installed models
* Download a model
* Show download progress
* Cancel download
* Validate model files
* Load model
* Unload model
* Display disk usage
* Display estimated memory use
* Delete model
* Show licence and source metadata

Store downloaded models under:

```text
~/Library/Application Support/AudiobookStudio/Models/
```

Temporary downloads can use:

```text
~/Library/Caches/AudiobookStudio/
```

Do not embed large models into the `.app`. The application bundle should contain code and lightweight resources only.

## LLM experiment

Start with one small quantised instruction model using MLX Swift LM.

Test:

* Model download
* Cold load time
* Warm load time
* Prompt execution
* Streaming tokens
* Structured JSON generation
* Cancellation
* Malformed JSON recovery
* Context-size limits
* Memory pressure
* Model unload
* Repeated inference

MLX Swift LM is an official Swift package for building applications around LLMs and VLMs in MLX Swift, and official examples include a minimal model-loading and prompt-evaluation application. ([GitHub][3])

Use an audiobook-relevant test prompt:

```text
Given this scene and the existing project character list:

1. Identify scene characters.
2. Reuse existing character IDs where appropriate.
3. Identify dialogue blocks and speakers.
4. Return strict JSON.
```

The spike must prove reliable decoding into Swift `Codable` models.

## Audio experiments

Separate audio capabilities into three interfaces even when an initial provider implements more than one:

```swift
protocol VoiceProfileGenerating
protocol SpeechGenerating
protocol SceneAudioGenerating
```

### Voice-profile experiment

Input:

* Description
* Accent
* Age range
* Tone
* Sample text
* Seed where supported

Output:

* Voice reference or model parameters
* Preview audio
* Reproducibility metadata

### Speech experiment

Input:

* Text
* Voice reference
* Performance direction
* Speaking rate
* Seed where supported

Output:

* Audio bytes
* Sample rate
* Channel count
* Duration
* Generation metadata

### Scene-audio experiment

Input:

* Scene summary
* Location
* Mood
* Music prompt
* Ambience prompt
* Requested duration

Output:

* Audio data
* Loopability indicator
* Duration
* Generation metadata

In practice, TTS, voice design, and music/SFX may require different models. The spike should not assume that one “audio model” will cover all three adequately.

## Model execution strategies to evaluate

### Option A: Native Swift model execution

Examples:

* MLX Swift
* MLX Swift LM
* Core ML
* Native model-specific Swift package

Advantages:

* Single application process
* Direct Swift types
* Better application lifecycle control
* Easier distribution once working

Risks:

* Some audio models may not have usable Swift implementations
* Conversion may be necessary
* Model architecture support may be incomplete

Apple positions Core ML as its framework for integrating machine-learning models into apps, while MLX Swift provides a Swift API designed for Apple-silicon model workloads. ([Apple Developer][4])

### Option B: Bundled helper executable

The Swift application launches an embedded helper process and communicates using JSON messages, pipes, or a local socket.

Advantages:

* Allows reuse of Python-based audio ecosystems
* Easier experimentation with unsupported audio models
* Models can be swapped rapidly

Risks:

* Much larger application footprint
* Python and native-library packaging
* Process supervision
* More complicated `.app` construction
* Harder future sandboxing
* Architecture-specific dependencies

Apple supports embedding helper tools in macOS applications, but this adds packaging and lifecycle considerations. ([Apple Developer][5])

For the spike, I would evaluate both but strongly prefer native Swift for the LLM. Use a helper only where the selected audio models have no realistic native Swift path.

## Model abstraction

The laboratory should expose provider-neutral requests:

```swift
struct LLMRequest: Sendable {
    let prompt: String
    let schema: JSONSchema?
    let temperature: Double
    let seed: UInt64?
}

struct SpeechRequest: Sendable {
    let text: String
    let voice: VoiceDescriptor
    let direction: PerformanceDirection
}

struct SceneAudioRequest: Sendable {
    let prompt: String
    let duration: Duration
    let shouldLoop: Bool
}
```

Implementations should be actors:

```swift
actor MLXLanguageModelService: LanguageModelServing
actor LocalSpeechModelService: SpeechGenerating
actor LocalSceneAudioModelService: SceneAudioGenerating
```

Inference should never execute on the main actor.

## Diagnostics to capture

Record:

* Hardware model
* macOS version
* Available memory
* Model name and revision
* Quantisation
* Download size
* Load time
* First-token latency
* Tokens per second
* Audio generation factor
* Peak memory
* Output duration
* Cancellation latency
* Model unload behaviour
* Thermal or memory-pressure failures

These measurements will determine which models are viable for the production application.

## Spike 2 completion criteria

The spike is complete when:

1. One local LLM can be downloaded, loaded, prompted, cancelled, and unloaded.
2. The LLM produces audiobook-analysis JSON decoded into Swift structures.
3. One speech model produces playable dialogue audio.
4. One voice-profile path is demonstrated, or clearly rejected as infeasible.
5. One music or ambience model produces playable scene audio.
6. Generated audio remains in memory or is imported immediately into a test SQLite database.
7. Model weights live in the application model cache, not in the project database.
8. The UI remains responsive during download and inference.
9. Failures are represented as typed Swift errors.
10. `make app` creates a manually openable laboratory `.app`.

---

# Repository structure

I recommend one repository containing both spikes and shared contracts:

```text
AudiobookStudio/
├── Package.swift
├── Makefile
├── README.md
├── Scripts/
│   ├── build-app.sh
│   ├── create-info-plist.sh
│   └── verify-app.sh
├── Sources/
│   ├── StudioApp/
│   │   ├── AudiobookStudioApp.swift
│   │   ├── Workflow/
│   │   ├── Screens/
│   │   ├── Components/
│   │   └── Resources/
│   ├── ModelLabApp/
│   │   ├── ModelLabApp.swift
│   │   ├── Screens/
│   │   └── Diagnostics/
│   ├── StudioDomain/
│   │   ├── Project.swift
│   │   ├── Chapter.swift
│   │   ├── Scene.swift
│   │   ├── Character.swift
│   │   ├── ScriptBlock.swift
│   │   └── WorkflowStage.swift
│   ├── StudioServices/
│   │   ├── Protocols/
│   │   └── Errors/
│   ├── StudioMocks/
│   ├── StudioPersistence/
│   └── StudioModels/
├── Tests/
│   ├── StudioDomainTests/
│   ├── StudioMocksTests/
│   └── StudioModelsTests/
└── .build/
    └── dist/
        ├── AudiobookStudio.app
        └── AudiobookModelLab.app
```

This produces two executables:

```text
AudiobookStudio
AudiobookModelLab
```

---

# Command-line `.app` packaging

A macOS `.app` is a directory with a defined bundle structure:

```text
AudiobookStudio.app/
└── Contents/
    ├── Info.plist
    ├── MacOS/
    │   └── AudiobookStudio
    └── Resources/
```

The packaging script should:

1. Run `swift build -c release`.
2. Create the bundle directories.
3. Copy the executable into `Contents/MacOS`.
4. Copy application resources.
5. Generate or copy `Info.plist`.
6. Add an application icon later.
7. Apply an ad-hoc signature.
8. Verify the bundle.
9. Place it under `.build/dist`.

Example commands:

```bash
swift build --configuration release --product AudiobookStudio

mkdir -p \
  .build/dist/AudiobookStudio.app/Contents/MacOS \
  .build/dist/AudiobookStudio.app/Contents/Resources

cp \
  .build/release/AudiobookStudio \
  .build/dist/AudiobookStudio.app/Contents/MacOS/AudiobookStudio

cp \
  Resources/Info.plist \
  .build/dist/AudiobookStudio.app/Contents/Info.plist

codesign \
  --force \
  --deep \
  --sign - \
  .build/dist/AudiobookStudio.app

open .build/dist/AudiobookStudio.app
```

An ad-hoc signature does not provide trusted distribution, but it is useful for locally assembled development bundles. Public distribution and Gatekeeper-friendly installation would later require Developer ID signing and notarisation; Apple supports archive and export operations from the command line when that becomes necessary. ([Apple Developer][6])

No Xcode UI is required. You will still need Apple’s development toolchain and macOS SDK installed. SwiftPM manages and builds the package from Terminal. ([Apple Developer][7])

---

# Build targets

Use these commands as the project contract:

```bash
make bootstrap
```

Checks Swift and required tools.

```bash
make studio
```

Builds the mocked studio executable.

```bash
make model-lab
```

Builds the model laboratory executable.

```bash
make test
```

Runs all tests.

```bash
make app
```

Produces both `.app` bundles.

```bash
make run-studio
```

Builds and opens the mocked studio.

```bash
make run-model-lab
```

Builds and opens the model laboratory.

```bash
make verify
```

Checks bundle structure, executable architecture, `Info.plist`, and signature.

---

# Recommended sequence

## First milestone

Complete the mocked Studio application.

Do not integrate real SQLite or models yet. Use realistic domain structures and service protocols, but keep the implementations mocked.

## Second milestone

Complete the Model Laboratory.

Select the actual LLM, TTS, voice-design, and music/SFX technologies based on measured performance rather than demos or assumptions.

## Third milestone

Implement a narrow SQLite persistence spike:

* Create project
* Store one chapter
* Store one voice preview as a blob
* Close and reopen
* Verify the project is self-contained
* Exercise schema migration and corruption handling

## Fourth milestone

Replace mock services one at a time:

```text
Mock repository → SQLite repository
Mock EPUB importer → Real EPUB importer
Mock scene analyser → Real LLM
Mock voice generator → Selected voice model
Mock speech generator → Selected TTS model
Mock background generator → Selected audio model
```

# Outstanding decisions

Before production implementation, record these explicitly:

1. **Minimum macOS version.** This affects APIs, testing, and model compatibility.
2. **Apple-silicon-only MVP.** Recommended because of local model execution.
3. **Model storage exception.** Recommended under Application Support or Caches.
4. **Minimum supported RAM.** Model tests should establish whether that is 16 GB, 24 GB, or higher.
5. **Offline requirement.** Decide whether all model downloads and inference must be local after initial installation.
6. **Model licensing.** Every selected model must permit the intended application and generated-audio use.
7. **Project size policy.** Storing every generated take and mixed asset in SQLite can produce very large files, so optimisation and deletion controls remain part of the MVP.

[1]: https://github.com/ml-explore/mlx-swift?utm_source=chatgpt.com "ml-explore/mlx-swift: Swift API for MLX"
[2]: https://developer.apple.com/swiftui/?utm_source=chatgpt.com "SwiftUI"
[3]: https://github.com/ml-explore/mlx-swift-lm?utm_source=chatgpt.com "ml-explore/mlx-swift-lm"
[4]: https://developer.apple.com/documentation/coreml/?utm_source=chatgpt.com "Core ML | Apple Developer Documentation"
[5]: https://developer.apple.com/documentation/xcode/embedding-a-helper-tool-in-a-sandboxed-app?utm_source=chatgpt.com "Embedding a command-line tool in a sandboxed app"
[6]: https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac?utm_source=chatgpt.com "Creating distribution-signed code for macOS"
[7]: https://developer.apple.com/download/?utm_source=chatgpt.com "Download"

Agreed. Model weights should be treated as a **shared external dependency**, not project content.

Hugging Face’s standard Hub cache defaults to `$HF_HOME/hub`, usually `~/.cache/huggingface/hub`, and can be overridden with `HF_HOME` or `HF_HUB_CACHE`. The app should respect those variables rather than inventing its own model directory. ([Hugging Face][1])

# Revised model architecture

## Supported backends

The model spike will support two interchangeable inference backends:

```text
MLX Swift
llama.cpp
```

Both use models published on Hugging Face.

### MLX backend

Expected model format:

* MLX-compatible weights
* Usually quantised `safetensors`
* Tokenizer and model configuration from the same repository

MLX Swift LM can load supported model architectures from Hugging Face and cache downloaded files locally. ([GitHub][2])

### llama.cpp backend

Expected model format:

* GGUF
* One model file or supported split GGUF files
* Optional tokenizer/chat-template metadata

The exact backend is selected per model configuration rather than globally.

```swift
enum InferenceBackend: String, Codable {
    case mlx
    case llamaCpp
}
```

---

# Hugging Face cache policy

## Resolution order

When the app needs a model, it performs these steps:

```text
1. Resolve configured Hugging Face cache path
2. Check for the exact repository and revision
3. Validate required files
4. Use the cached snapshot when complete
5. Download missing files when online
6. Revalidate the completed snapshot
7. Load through the selected inference backend
```

The application must never redownload a valid model merely because it did not originally download it.

This allows users to prepopulate the cache using:

* Hugging Face CLI
* Python libraries
* Another application
* A previous run of Audiobook Studio

## Cache location resolution

Use the standard Hugging Face precedence:

```text
HF_HUB_CACHE
    ↓
HF_HOME/hub
    ↓
~/.cache/huggingface/hub
```

The app should expand environment variables and symbolic links before using the path.

```swift
struct HuggingFaceCacheConfiguration {
    let homeDirectory: URL
    let hubCacheDirectory: URL
}
```

The application settings screen should show the resolved cache location but not silently relocate it.

Possible UI:

```text
Hugging Face cache

~/.cache/huggingface/hub

Source: Default location
Status: Accessible
Disk usage: 18.4 GB

[Reveal in Finder]
[Rescan]
```

If `HF_HUB_CACHE` is present:

```text
Source: HF_HUB_CACHE environment variable
```

Hugging Face documents the cache layout specifically so that tools in different languages can interoperate with it. ([Hugging Face][3])

---

# Important cache rule

Do not search the cache by filename alone.

A model should be identified by:

```text
Repository ID
Revision or commit hash
Required filenames
Backend
Quantisation
```

Example:

```swift
struct ModelIdentity: Hashable, Codable {
    let repositoryID: String
    let revision: String
    let backend: InferenceBackend
    let requiredFiles: [String]
}
```

Example MLX model:

```text
Repository:
mlx-community/Example-Model-4bit

Revision:
specific commit hash

Required files:
config.json
tokenizer.json
tokenizer_config.json
model.safetensors.index.json
model-00001-of-00002.safetensors
model-00002-of-00002.safetensors
```

Example llama.cpp model:

```text
Repository:
publisher/Example-Model-GGUF

Revision:
specific commit hash

Required files:
example-model-Q4_K_M.gguf
```

A repository can contain several quantisations, so the filename remains part of the model specification.

---

# Snapshot resolution

The shared resolver should understand the standard Hugging Face cache structure:

```text
hub/
└── models--publisher--repository/
    ├── blobs/
    ├── refs/
    └── snapshots/
        └── <commit-hash>/
            ├── config.json
            ├── tokenizer.json
            └── model files
```

The app should resolve a branch or tag such as `main` through the corresponding reference and then operate on the immutable snapshot directory.

Do not load directly from arbitrary blobs.

## Exact revision preference

For reproducibility, application model definitions should pin a commit hash:

```json
{
  "id": "scene-analysis-default",
  "repository": "mlx-community/example-model-4bit",
  "revision": "76f8a1...",
  "backend": "mlx"
}
```

A friendly channel such as `recommended` may point to this definition, but each project stores the exact resolved revision.

---

# Download strategy

## Prefer an embedded native downloader

The app should not require users to install Python or the Hugging Face CLI.

Create a Swift service:

```swift
protocol HuggingFaceRepositoryServing: Sendable {
    func inspect(_ specification: HuggingFaceModelSpecification) async throws
        -> CachedModelStatus

    func download(
        _ specification: HuggingFaceModelSpecification,
        progress: @escaping @Sendable (ModelDownloadProgress) -> Void
    ) async throws -> ResolvedModel
}
```

It should:

* Query repository metadata
* Resolve a revision to a commit
* Download only required files
* Support gated repositories
* Resume partial downloads where safe
* Verify size and available integrity metadata
* Write files into the Hugging Face cache layout
* Use atomic completion
* Honour cancellation
* Never expose a partial snapshot as ready

## Temporary download files

Temporary fragments may be placed inside the Hugging Face cache’s own download mechanism or the system temporary directory.

They are not project assets and do not violate the single-project-file rule.

---

# Offline behaviour

Add a clear offline option:

```text
Model access

○ Online — use cache and download missing models
● Cache only — never access the network
```

In cache-only mode:

* Scan the cache
* Resolve available revisions
* Load valid models
* Report missing files
* Never attempt a network request

Failure should be explicit:

```text
Model unavailable offline

Repository:
mlx-community/example-model-4bit

Revision:
76f8a1…

Missing:
model-00002-of-00002.safetensors
```

Do not silently load another revision when the requested revision is unavailable. This is especially important because recent llama.cpp cache behaviour has had edge cases around offline revision selection. ([GitHub][4])

---

# Authentication

Some Hugging Face models may be gated.

Authentication should be resolved in this order:

```text
HF_TOKEN environment variable
    ↓
Existing Hugging Face token location under HF_HOME
    ↓
Token configured through application settings
```

Hugging Face stores its token beneath `HF_HOME` by default. ([Hugging Face][1])

Application-entered tokens should be stored in macOS Keychain, not plain application configuration.

The UI should never display the full token.

---

# Updated model definition

```swift
struct HuggingFaceModelSpecification: Codable, Identifiable {
    let id: String

    let displayName: String
    let purpose: ModelPurpose
    let backend: InferenceBackend

    let repositoryID: String
    let revision: String
    let requiredFiles: [RequiredModelFile]

    let contextLength: Int?
    let estimatedMemoryBytes: Int64?
    let minimumMemoryBytes: Int64?

    let licenseIdentifier: String?
    let gated: Bool
}
```

```swift
enum ModelPurpose: String, Codable {
    case sceneDetection
    case characterDetection
    case dialogueAttribution
    case speech
    case voiceDesign
    case backgroundAudio
}
```

```swift
struct RequiredModelFile: Codable {
    let path: String
    let expectedSize: Int64?
    let checksum: String?
}
```

---

# Shared model resolver

Both inference engines should depend on one resolver:

```text
Model Registry
      ↓
Hugging Face Cache Resolver
      ↓
Resolved snapshot/file URLs
      ├── MLX Loader
      └── llama.cpp Loader
```

```swift
actor ModelResolver {
    func resolve(
        _ specification: HuggingFaceModelSpecification,
        policy: ModelAccessPolicy
    ) async throws -> ResolvedModel
}
```

```swift
struct ResolvedModel {
    let specification: HuggingFaceModelSpecification
    let snapshotDirectory: URL
    let modelFiles: [URL]
    let resolvedCommit: String
    let wasAlreadyCached: Bool
}
```

The inference backends must not independently download models. That prevents duplicate files and inconsistent cache behaviour.

---

# MLX adapter

```swift
actor MLXLanguageModelService: LanguageModelServing {
    private let resolver: ModelResolver

    func load(_ specification: HuggingFaceModelSpecification) async throws {
        let resolved = try await resolver.resolve(
            specification,
            policy: .downloadIfMissing
        )

        // Initialise the MLX container using resolved.snapshotDirectory.
    }
}
```

Responsibilities:

* Confirm the model architecture is supported by the current MLX Swift LM version
* Load from the resolved local snapshot
* Stream generation
* Cancel generation
* Release the model container
* Report memory usage and load timing

A model being present in Hugging Face does not guarantee that its architecture is supported by MLX Swift LM, so compatibility must be validated independently. ([GitHub][5])

---

# llama.cpp adapter

For the spike, there are two reasonable approaches.

## Preferred: link llama.cpp as a native library

Expose a small Swift/C bridge around:

* Model loading
* Context creation
* Tokenisation
* Generation
* Cancellation
* Structured grammar constraints
* Resource teardown

Advantages:

* No server process
* Lower operational complexity
* Direct lifecycle control
* Easier offline operation

## Alternative: bundle `llama-server`

The app can launch a bundled `llama-server` and communicate over localhost.

This is easier for an early spike but introduces:

* Process supervision
* Port management
* Startup health checks
* Shutdown handling
* Local HTTP transport
* Additional logs
* Potential firewall prompts or conflicts

The resolver should still provide a direct GGUF path from the Hugging Face snapshot:

```bash
llama-server \
  --model "/resolved/huggingface/snapshot/model-Q4_K_M.gguf"
```

Do not rely on llama.cpp’s separate default cache as the primary cache. While llama.cpp supports its own cache controls, using the Hugging Face Hub cache as the application’s common source avoids parallel copies between MLX and llama.cpp. llama.cpp’s server documentation describes its own `LLAMA_CACHE`, so this distinction should be explicit. ([GitHub][6])

---

# Backend selection

A model is tied to a compatible backend.

```text
MLX-format repository → MLX
GGUF repository → llama.cpp
```

The UI should not offer arbitrary switching for the same physical model files.

However, the model registry may provide alternatives for the same task:

```text
Scene analysis

● Qwen 3 4B MLX
  Backend: MLX
  Download: 2.6 GB

○ Qwen 3 4B GGUF Q4_K_M
  Backend: llama.cpp
  Download: 2.8 GB
```

This lets the spike compare:

* Load time
* Tokens per second
* Structured-output reliability
* Memory usage
* Cancellation
* Packaging complexity

---

# Model state in the project database

The SQLite project stores model references, not weights:

```text
model_assignments
- purpose
- repository_id
- revision
- backend
- selected_filename
- generation_parameters
```

Every AI result also records:

```text
provider: local
backend: mlx
repository_id: mlx-community/example-model-4bit
revision: 76f8a1…
prompt_version: scene-detection-v3
parameters: …
```

When reopening a project:

1. Read the required model reference.
2. Check the Hugging Face cache.
3. Show the model as available or missing.
4. Offer to download it when missing.
5. Do not alter existing generated project results.

Thus the project remains portable, although regenerating content requires access to the referenced models.

---

# Revised model-lab screens

## Models

Show:

* Task
* Model name
* Backend
* Repository
* Revision
* Quantisation
* Cache state
* Required disk space
* Installed size
* Compatibility
* Licence
* Load state

Statuses:

```text
Cached
Partially cached
Missing
Downloading
Verifying
Incompatible
Gated
Corrupt
Loaded
```

## Cache inspector

Add a diagnostic screen showing:

* Resolved Hugging Face cache path
* Relevant environment variables
* Discovered model repositories
* Snapshot revisions
* Missing files
* Broken symbolic links
* Total model disk usage
* Models known to Audiobook Studio
* Unrecognised cached repositories

Do not provide broad cache deletion in the initial spike because other tools may share it.

The app may offer:

```text
Remove this model snapshot
```

but it should clearly warn that other applications may also use it.

---

# Updated Spike 2 completion criteria

The model spike is complete when:

1. The app resolves `HF_HUB_CACHE`, `HF_HOME`, and the default Hugging Face cache correctly.
2. It detects a model downloaded previously by another Hugging Face-compatible tool.
3. It loads a cached MLX model without network access.
4. It loads a cached GGUF model through llama.cpp without network access.
5. It downloads a missing model into the standard Hugging Face cache.
6. A cancelled download does not create a valid-looking snapshot.
7. Cache-only mode makes no network requests.
8. Exact repository revision and required filenames are recorded.
9. A gated-model authentication failure is clearly reported.
10. MLX and llama.cpp satisfy the same `LanguageModelServing` interface.
11. Both produce output decoded into the same Swift `Codable` response type.
12. The project database stores only model references and generated results, never model weights.
13. The app bundle contains neither model weights nor a private duplicate model cache.
14. The `.app` is still produced entirely through SwiftPM and command-line scripts.

# Updated repository modules

```text
Sources/
├── ModelRegistry/
│   ├── ModelPurpose.swift
│   ├── ModelSpecification.swift
│   └── BundledModelCatalogue.swift
├── HuggingFaceCache/
│   ├── CacheConfiguration.swift
│   ├── CacheLayout.swift
│   ├── CacheScanner.swift
│   ├── RepositoryClient.swift
│   ├── ModelResolver.swift
│   └── AuthenticationProvider.swift
├── MLXBackend/
│   └── MLXLanguageModelService.swift
├── LlamaCppBackend/
│   ├── LlamaCppLanguageModelService.swift
│   └── CLlamaBridge/
└── ModelLabApp/
```

The key architectural rule is now:

```text
Hugging Face owns model storage.
ModelResolver owns cache discovery and downloads.
MLX and llama.cpp only load resolved local files.
Projects store model identities, not weights.
```

[1]: https://huggingface.co/docs/huggingface_hub/package_reference/environment_variables?utm_source=chatgpt.com "Environment variables"
[2]: https://github.com/ml-explore/mlx-swift-examples/blob/main/Applications/LLMEval/README.md?utm_source=chatgpt.com "LLMEval - ml-explore/mlx-swift-examples"
[3]: https://huggingface.co/docs/hub/local-cache?utm_source=chatgpt.com "Hub Local Cache"
[4]: https://github.com/ggml-org/llama.cpp/issues/21364?utm_source=chatgpt.com "Misc. bug: issues with hf cache since path consolidation ..."
[5]: https://github.com/ml-explore/mlx-swift/issues/389?utm_source=chatgpt.com "[BUG] Add Gemma 4 model architecture support (gemma4)"
[6]: https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md?utm_source=chatgpt.com "llama.cpp/tools/server/README.md at master · ggml-org ..."
