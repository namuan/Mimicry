import Foundation
import StudioDomain

/// Builds a representative sample project for the mocked studio UI.
public enum MockSampleData {

    // MARK: - IDs

    public static let projectID = Project.ID()

    public static let chapter1ID = Chapter.ID()
    public static let chapter2ID = Chapter.ID()
    public static let chapter3ID = Chapter.ID()

    public static let scene1_1ID = Scene.ID()
    public static let scene1_2ID = Scene.ID()
    public static let scene1_3ID = Scene.ID()
    public static let scene2_1ID = Scene.ID()
    public static let scene2_2ID = Scene.ID()
    public static let scene2_3ID = Scene.ID()
    public static let scene2_4ID = Scene.ID()
    public static let scene3_1ID = Scene.ID()
    public static let scene3_2ID = Scene.ID()
    public static let scene3_3ID = Scene.ID()

    public static let narratorID = Character.ID()
    public static let elenaID = Character.ID()
    public static let marcusID = Character.ID()
    public static let kaiID = Character.ID()
    public static let directorID = Character.ID()
    public static let guardID = Character.ID()
    public static let doctorAliasID = Character.ID()

    public static let narratorVoiceID = VoiceProfile.ID()
    public static let elenaVoice1ID = VoiceProfile.ID()
    public static let elenaVoice2ID = VoiceProfile.ID()
    public static let marcusVoiceID = VoiceProfile.ID()
    public static let kaiVoiceID = VoiceProfile.ID()
    public static let directorVoiceID = VoiceProfile.ID()
    public static let guardVoiceID = VoiceProfile.ID()
    public static let doctorVoiceID = VoiceProfile.ID()

    // MARK: - Builders

    public static func buildProject() -> Project {
        let chapters = buildChapters()
        let scenes = buildScenes()
        let blocks = buildBlocks()
        let characters = buildCharacters()
        let voices = buildVoiceProfiles()
        let soundDesigns = buildSoundDesigns()

        let workflowStages = WorkflowStage.allCases.map { stage in
            let status: WorkflowStageStatus = switch stage {
            case .import: .complete
            case .structure: .needsReview
            case .characters: .needsReview
            case .script: .available
            case .voices: .available
            case .soundDesign: .notStarted
            case .generate: .notStarted
            case .review: .notStarted
            case .export: .notStarted
            }
            return WorkflowStageInfo(stage: stage, status: status)
        }

        let reviewIssues = buildReviewIssues()
        let jobs = buildGenerationJobs()

        return Project(
            id: projectID,
            title: "The Shadow Protocol",
            author: "Catherine M. Vance",
            chapters: chapters,
            characters: characters,
            scenes: scenes,
            blocks: blocks,
            voiceProfiles: voices,
            soundDesigns: soundDesigns,
            narratorID: narratorID,
            workflowStages: workflowStages,
            reviewIssues: reviewIssues,
            generationJobs: jobs
        )
    }

    // MARK: - Chapters

    private static func buildChapters() -> [Chapter] {
        [
            Chapter(
                id: chapter1ID,
                title: "The Package",
                number: 1,
                order: 0,
                sceneIDs: [scene1_1ID, scene1_2ID, scene1_3ID]
            ),
            Chapter(
                id: chapter2ID,
                title: "Safe House",
                number: 2,
                order: 1,
                sceneIDs: [scene2_1ID, scene2_2ID, scene2_3ID, scene2_4ID]
            ),
            Chapter(
                id: chapter3ID,
                title: "The Exchange",
                number: 3,
                order: 2,
                sceneIDs: [scene3_1ID, scene3_2ID, scene3_3ID]
            ),
        ]
    }

    // MARK: - Scenes

    private static func buildScenes() -> [Scene] {
        [
            Scene(
                id: scene1_1ID, chapterID: chapter1ID,
                title: "The Courier",
                summary: "Elena receives a mysterious package at her Vienna apartment. Tension builds as she notices a figure watching from across the street.",
                order: 0,
                sceneBoundaryConfidence: 0.95,
                location: "Elena's apartment, Vienna",
                mood: "Tense, foreboding"
            ),
            Scene(
                id: scene1_2ID, chapterID: chapter1ID,
                title: "The Chase",
                summary: "Elena flees through the streets of Vienna. Marcus intercepts her at the opera house.",
                order: 1,
                sceneBoundaryConfidence: 0.72,
                location: "Streets of Vienna / Opera House",
                mood: "Urgent, chaotic"
            ),
            Scene(
                id: scene1_3ID, chapterID: chapter1ID,
                title: "The Briefing",
                summary: "At a secure location, Marcus briefs Elena on the contents of the package. Director Kessler appears via video link.",
                order: 2,
                sceneBoundaryConfidence: 0.88,
                location: "Safe house, unknown location",
                mood: "Revelatory, tense"
            ),
            Scene(
                id: scene2_1ID, chapterID: chapter2ID,
                title: "Arrival",
                summary: "The team arrives at the safe house. Kai, the tech specialist, has already set up surveillance.",
                order: 0,
                sceneBoundaryConfidence: 0.91,
                location: "Rural safe house, Carpathian foothills",
                mood: "Cautious, establishing"
            ),
            Scene(
                id: scene2_2ID, chapterID: chapter2ID,
                title: "The Interrogation",
                summary: "Marcus interrogates a captured courier. The guard outside hears disturbing sounds.",
                order: 1,
                sceneBoundaryConfidence: 0.85,
                location: "Basement of safe house",
                mood: "Dark, intense"
            ),
            Scene(
                id: scene2_3ID, chapterID: chapter2ID,
                title: "Kai's Discovery",
                summary: "Kai discovers encrypted files on the courier's device. The encryption is military-grade.",
                order: 2,
                sceneBoundaryConfidence: 0.93,
                location: "Tech room, safe house",
                mood: "Focused, urgent"
            ),
            Scene(
                id: scene2_4ID, chapterID: chapter2ID,
                title: "The Betrayal",
                summary: "Elena discovers that someone inside the team has been communicating with the enemy. Suspicion falls on Kai.",
                order: 3,
                sceneBoundaryConfidence: 0.68,
                location: "Living quarters, safe house",
                mood: "Paranoid, accusatory"
            ),
            Scene(
                id: scene3_1ID, chapterID: chapter3ID,
                title: "The Drop",
                summary: "The team sets up the exchange at an abandoned train yard. Elena acts as the courier.",
                order: 0,
                sceneBoundaryConfidence: 0.90,
                location: "Abandoned train yard, outskirts of Brasov",
                mood: "Tense, cinematic"
            ),
            Scene(
                id: scene3_2ID, chapterID: chapter3ID,
                title: "Double Cross",
                summary: "The exchange goes wrong. Gunfire erupts. The Director's true allegiance is revealed.",
                order: 1,
                sceneBoundaryConfidence: 0.94,
                location: "Train yard, night",
                mood: "Chaotic, violent"
            ),
            Scene(
                id: scene3_3ID, chapterID: chapter3ID,
                title: "Aftermath",
                summary: "In the aftermath of the shootout, Elena and Marcus confront the Director. The package's true nature is finally understood.",
                order: 2,
                sceneBoundaryConfidence: 0.87,
                location: "Director's office, Bucharest",
                mood: "Resolute, cathartic"
            ),
        ]
    }

    // MARK: - Characters

    private static func buildCharacters() -> [Character] {
        [
            Character(
                id: narratorID,
                name: "Narrator",
                isNarrator: true,
                description: "Third-person omniscient narrator with a warm, authoritative tone. Occasionally dips into close third-person for Elena.",
                voiceProfileID: narratorVoiceID
            ),
            Character(
                id: elenaID,
                name: "Elena Vasquez",
                aliases: ["Elena", "Ms. Vasquez"],
                description: "Protagonist. Former intelligence analyst turned courier. Late 30s, sharp, multilingual, carries unresolved grief.",
                sceneAppearances: [scene1_1ID, scene1_2ID, scene1_3ID, scene2_1ID, scene2_4ID, scene3_1ID, scene3_2ID, scene3_3ID],
                voiceProfileID: elenaVoice1ID
            ),
            Character(
                id: marcusID,
                name: "Marcus Cole",
                aliases: ["Marcus"],
                description: "Ex-military operative, team leader. Early 40s, calm under pressure, speaks in clipped sentences. Deep baritone voice.",
                sceneAppearances: [scene1_2ID, scene1_3ID, scene2_1ID, scene2_2ID, scene3_1ID, scene3_2ID, scene3_3ID],
                voiceProfileID: marcusVoiceID
            ),
            Character(
                id: kaiID,
                name: "Kai Nakamura",
                aliases: ["Kai"],
                description: "Tech and surveillance specialist. Late 20s, quiet, brilliant, socially awkward. Speaks quickly when excited.",
                sceneAppearances: [scene2_1ID, scene2_3ID, scene2_4ID, scene3_1ID, scene3_2ID],
                voiceProfileID: kaiVoiceID
            ),
            Character(
                id: directorID,
                name: "Director Anton Kessler",
                aliases: ["Director Kessler", "The Director", "Kessler"],
                description: "Senior intelligence director. Late 50s, calculating, avuncular surface hiding ruthless pragmatism. Speaks with a slight Austrian accent.",
                sceneAppearances: [scene1_3ID, scene3_2ID, scene3_3ID],
                voiceProfileID: directorVoiceID
            ),
            Character(
                id: guardID,
                name: "Unnamed Guard",
                aliases: ["the guard", "The Guard"],
                description: "A security guard at the safe house. Young, nervous, Eastern European. Speaks from another room in scene 2.2.",
                sceneAppearances: [scene2_2ID],
                voiceProfileID: guardVoiceID
            ),
            Character(
                id: doctorAliasID,
                name: "Dr. Helena Vance",
                aliases: ["Doctor Vance", "The Doctor"],
                description: "A mysterious contact mentioned in Elena's brief. Possibly an alias used by Elena herself. Age and gender unconfirmed.",
                sceneAppearances: [scene1_3ID],
                voiceProfileID: doctorVoiceID,
                notes: "POTENTIAL DUPLICATE: May be an alias used by Elena Vasquez. Both are described as female intelligence contacts in Vienna. Review required."
            ),
        ]
    }

    // MARK: - Voice Profiles

    private static func buildVoiceProfiles() -> [VoiceProfile] {
        let tone1 = MockAudioGenerator.generateTone(frequency: 220, duration: 2.0)
        let tone2 = MockAudioGenerator.generateTone(frequency: 330, duration: 2.0)
        let tone3 = MockAudioGenerator.generateTone(frequency: 440, duration: 2.0)
        let tone4 = MockAudioGenerator.generateTone(frequency: 277, duration: 2.0)
        let tone5 = MockAudioGenerator.generateTone(frequency: 175, duration: 2.0)
        let tone6 = MockAudioGenerator.generateTone(frequency: 392, duration: 2.0)

        return [
            VoiceProfile(
                id: narratorVoiceID, name: "James - British Baritone",
                description: "Warm, authoritative British male voice. Clear enunciation, natural pacing.",
                accent: "British RP", tone: "Warm, authoritative",
                sampleText: "The package arrived on a Tuesday, wrapped in brown paper and silence.",
                seed: 42, isNarratorVoice: true,
                previewAudioData: tone1,
                generationMetadata: ["model": "mock-tts-v1"]
            ),
            VoiceProfile(
                id: elenaVoice1ID, name: "Sofia - American Alto",
                description: "Confident but vulnerable. American accent, alto range, occasional breathiness when emotional.",
                accent: "American", ageRange: "35-40", tone: "Confident, vulnerable",
                sampleText: "We shouldn't be here.", seed: 101,
                previewAudioData: tone2,
                generationMetadata: ["model": "mock-tts-v1"]
            ),
            VoiceProfile(
                id: elenaVoice2ID, name: "Clara - Neutral American",
                description: "Clear, professional American female voice. Less character than Sofia but more versatile.",
                accent: "American", ageRange: "30-45", tone: "Professional, clear",
                sampleText: "The package contains classified intelligence.", seed: 102,
                previewAudioData: tone3,
                generationMetadata: ["model": "mock-tts-v1"]
            ),
            VoiceProfile(
                id: marcusVoiceID, name: "Marcus - Deep Baritone",
                description: "Commanding, deep male voice. Clipped delivery, military cadence.",
                accent: "American", ageRange: "40-45", tone: "Commanding, clipped",
                sampleText: "You said that ten minutes ago.", seed: 200,
                previewAudioData: tone4,
                generationMetadata: ["model": "mock-tts-v1"]
            ),
            VoiceProfile(
                id: kaiVoiceID, name: "Kenji - Fast Tenor",
                description: "Younger male voice, fast and precise. Slightly nasal, excitable under pressure.",
                accent: "American (Japanese-American)", ageRange: "25-30", tone: "Fast, precise",
                sampleText: "The encryption is military-grade. I can crack it, but I need time.",
                seed: 300, previewAudioData: tone5,
                generationMetadata: ["model": "mock-tts-v1"]
            ),
            VoiceProfile(
                id: directorVoiceID, name: "Kessler - Austrian Accent",
                description: "Older male voice. Austrian-accented English, avuncular warmth with an edge of menace.",
                accent: "Austrian", ageRange: "55-60", tone: "Avuncular, menacing",
                sampleText: "Trust is a currency, Elena. Spend it wisely.",
                seed: 400, previewAudioData: tone6,
                generationMetadata: ["model": "mock-tts-v1"]
            ),
            VoiceProfile(
                id: guardVoiceID, name: "Andrei - Eastern European Baritone",
                description: "Young male voice. Eastern European accent, nervous energy, speaks in short sentences.",
                accent: "Romanian", ageRange: "22-28", tone: "Nervous, gruff",
                sampleText: "I didn't see anything. I was outside.",
                seed: 500, previewAudioData: tone4,
                generationMetadata: ["model": "mock-tts-v1"]
            ),
            VoiceProfile(
                id: doctorVoiceID, name: "Helena - Austrian Alto",
                description: "Mature female voice. Austrian-accented, precise, clinical.",
                accent: "Austrian", ageRange: "45-55", tone: "Precise, clinical",
                sampleText: "The patient shows remarkable recovery. Remarkable.",
                seed: 600, previewAudioData: tone4,
                generationMetadata: ["model": "mock-tts-v1"]
            ),
        ]
    }

    // MARK: - Script Blocks

    private static func buildBlocks() -> [ScriptBlock] {
        [
            // Scene 1.1 - The Courier
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene1_1ID, type: .narration,
                productionText: "The corridor was completely dark.",
                sourceText: "The corridor was completely dark.",
                order: 0),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene1_1ID, type: .narration,
                productionText: "Elena pressed her back against the cold wall, listening to the footsteps in the stairwell below.",
                sourceText: "Elena pressed her back against the cold wall, listening to the footsteps in the stairwell below.",
                order: 1),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene1_1ID, type: .dialogue,
                productionText: "\"Who's there?\"",
                sourceText: "\"Who's there?\"",
                speakerID: elenaID, speakerConfidence: 0.95,
                order: 2),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene1_1ID, type: .narration,
                productionText: "Silence. Then the footsteps resumed — closer now, deliberate.",
                sourceText: "Silence. Then the footsteps resumed — closer now, deliberate.",
                order: 3),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene1_1ID, type: .thought,
                productionText: "She shouldn't have taken the package. She knew that now, with the certainty of cold metal against her spine.",
                sourceText: "She shouldn't have taken the package. She knew that now, with the certainty of cold metal against her spine.",
                speakerID: elenaID, speakerConfidence: 0.90,
                order: 4, performanceDirection: "Internal monologue, whispered intensity"),

            // Scene 1.2 - The Chase
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene1_2ID, type: .narration,
                productionText: "Vienna's streets blurred past as Elena ran.",
                sourceText: "Vienna's streets blurred past as Elena ran.",
                order: 0),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene1_2ID, type: .dialogue,
                productionText: "\"Stop running, Elena. I'm not here to hurt you.\"",
                sourceText: "\"Stop running, Elena. I'm not here to hurt you.\"",
                speakerID: marcusID, speakerConfidence: 0.88,
                order: 1, performanceDirection: "Calm, authoritative, barely winded"),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene1_2ID, type: .dialogue,
                productionText: "\"You said that ten minutes ago.\"",
                sourceText: "\"You said that ten minutes ago.\"",
                speakerID: elenaID, speakerConfidence: 0.92,
                order: 2, performanceDirection: "Breathless, defiant"),
            // INTENTIONAL: dialogue with no explicit speaker
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene1_2ID, type: .dialogue,
                productionText: "\"Move. Now.\"",
                sourceText: "\"Move. Now.\"",
                speakerID: nil, speakerConfidence: nil,
                order: 3, performanceDirection: "Urgent, whispered — unclear if Marcus or an unknown voice"),

            // Scene 1.3 - The Briefing
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene1_3ID, type: .narration,
                productionText: "The safe house was sparse: a table, four chairs, and a laptop streaming a grainy video feed.",
                sourceText: "The safe house was sparse: a table, four chairs, and a laptop streaming a grainy video feed.",
                order: 0),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene1_3ID, type: .dialogue,
                productionText: "\"The package contains a list. Names of operatives embedded across Eastern Europe.\"",
                sourceText: "\"The package contains a list. Names of operatives embedded across Eastern Europe.\"",
                speakerID: marcusID, speakerConfidence: 0.96,
                order: 1),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene1_3ID, type: .dialogue,
                productionText: "\"That's not a list. That's a death warrant.\"",
                sourceText: "\"That's not a list. That's a death warrant.\"",
                speakerID: elenaID, speakerConfidence: 0.93,
                order: 2, performanceDirection: "Shocked, processing the implications"),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene1_3ID, type: .narration,
                productionText: "The laptop screen flickered. A face appeared — lined, paternal, with eyes that held no warmth.",
                sourceText: "The laptop screen flickered. A face appeared — lined, paternal, with eyes that held no warmth.",
                order: 3),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene1_3ID, type: .dialogue,
                productionText: "\"Ms. Vasquez. I've heard a great deal about you. All of it impressive.\"",
                sourceText: "\"Ms. Vasquez. I've heard a great deal about you. All of it impressive.\"",
                speakerID: directorID, speakerConfidence: 0.91,
                order: 4, performanceDirection: "Warm but calculating, slight Austrian accent"),

            // Scene 2.1 - Arrival
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene2_1ID, type: .narration,
                productionText: "The safe house emerged from the fog like a forgotten memory — stone walls, iron gates, a single light burning in an upper window.",
                sourceText: "The safe house emerged from the fog like a forgotten memory — stone walls, iron gates, a single light burning in an upper window.",
                order: 0),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene2_1ID, type: .dialogue,
                productionText: "\"Perimeter is clean. I've got motion sensors on all approaches.\"",
                sourceText: "\"Perimeter is clean. I've got motion sensors on all approaches.\"",
                speakerID: kaiID, speakerConfidence: 0.94,
                order: 1, performanceDirection: "Fast, precise, not looking up from laptop"),

            // Scene 2.2 - The Interrogation (contains awkward cases)
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene2_2ID, type: .narration,
                productionText: "The basement smelled of damp stone and old fear. Marcus stood with his back to the single bulb, his shadow swallowing the man in the chair.",
                sourceText: "The basement smelled of damp stone and old fear. Marcus stood with his back to the single bulb, his shadow swallowing the man in the chair.",
                order: 0),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene2_2ID, type: .narration,
                productionText: "Above, in the corridor, the guard shifted his weight from foot to foot. He could hear voices but not words.",
                sourceText: "Above, in the corridor, the guard shifted his weight from foot to foot. He could hear voices but not words.",
                order: 1),
            // Character speaking from another room
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene2_2ID, type: .dialogue,
                productionText: "\"Is everything all right down there?\"",
                sourceText: "\"Is everything all right down there?\"",
                speakerID: guardID, speakerConfidence: 0.78,
                order: 2, performanceDirection: "Called from upstairs, nervous, muffled through door"),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene2_2ID, type: .dialogue,
                productionText: "\"Stay at your post.\"",
                sourceText: "\"Stay at your post.\"",
                speakerID: marcusID, speakerConfidence: 0.97,
                order: 3, performanceDirection: "Flat, not turning around"),
            // INTENTIONAL: no narrator label but narrator speaking — narration block that reads like character POV
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene2_2ID, type: .thought,
                productionText: "The guard had been doing this job for three months. He had never heard anyone scream before tonight. He wondered if that made him complicit.",
                sourceText: "The guard had been doing this job for three months. He had never heard anyone scream before tonight. He wondered if that made him complicit.",
                speakerID: guardID, speakerConfidence: 0.65,
                order: 4, performanceDirection: "Internal thought, the guard's POV — could be narration or character interiority"),

            // Scene 2.3 - Kai's Discovery
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene2_3ID, type: .dialogue,
                productionText: "\"This encryption is military-grade. NSA-level.\"",
                sourceText: "\"This encryption is military-grade. NSA-level.\"",
                speakerID: kaiID, speakerConfidence: 0.95,
                order: 0, performanceDirection: "Excited, talking fast"),
            // INTENTIONAL: ambiguous speaker — could be Kai continuing or Marcus
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene2_3ID, type: .dialogue,
                productionText: "\"Can you break it?\"",
                sourceText: "\"Can you break it?\"",
                speakerID: nil, speakerConfidence: nil,
                order: 1),

            // Scene 2.4 - The Betrayal
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene2_4ID, type: .narration,
                productionText: "Elena found the satellite phone under Kai's mattress at 3 AM. The call log showed eleven outgoing calls to a Bucharest number.",
                sourceText: "Elena found the satellite phone under Kai's mattress at 3 AM. The call log showed eleven outgoing calls to a Bucharest number.",
                order: 0),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene2_4ID, type: .dialogue,
                productionText: "\"It's not what you think.\"",
                sourceText: "\"It's not what you think.\"",
                speakerID: kaiID, speakerConfidence: 0.89,
                order: 1, performanceDirection: "Desperate, caught off guard"),

            // Scene 3.1 - The Drop (includes narrator who also speaks — narration preceding dialogue in same block style)
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene3_1ID, type: .narration,
                productionText: "The train yard stretched out before them, a graveyard of rusted steel and shattered windows. Elena's heart hammered against her ribs.",
                sourceText: "The train yard stretched out before them, a graveyard of rusted steel and shattered windows. Elena noted every exit, every shadow, every potential sightline — the habits of her former life still serving her.",
                order: 0),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene3_1ID, type: .dialogue,
                productionText: "\"Package is in position. I repeat, package is in position.\"",
                sourceText: "\"Package is in position. I repeat, package is in position.\"",
                speakerID: elenaID, speakerConfidence: 0.96,
                order: 1, performanceDirection: "Whispered into comm, tense"),

            // Scene 3.2 - Double Cross
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene3_2ID, type: .narration,
                productionText: "The first shot came from the east tower. The second from behind the rusted locomotive. Elena hit the ground before her brain registered the sound.",
                sourceText: "The first shot came from the east tower. The second from behind the rusted locomotive. Elena hit the ground before her brain registered the sound.",
                order: 0),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene3_2ID, type: .dialogue,
                productionText: "\"Kessler!\"",
                sourceText: "\"Kessler!\"",
                speakerID: nil, speakerConfidence: nil,
                order: 1, performanceDirection: "Shouted across the train yard, speaker unclear"),

            // Scene 3.3 - Aftermath
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene3_3ID, type: .dialogue,
                productionText: "\"You were never the courier. You were the package.\"",
                sourceText: "\"You were never the courier. You were the package.\"",
                speakerID: directorID, speakerConfidence: 0.90,
                order: 0, performanceDirection: "Calm, almost amused, sitting behind a vast desk"),
            ScriptBlock(id: ScriptBlock.ID(), sceneID: scene3_3ID, type: .dialogue,
                productionText: "\"The list wasn't operatives. It was proof. Proof of what you've been doing.\"",
                sourceText: "\"The list wasn't operatives. It was proof. Proof of what you've been doing.\"",
                speakerID: elenaID, speakerConfidence: 0.94,
                order: 1, performanceDirection: "Defiant, exhausted but resolute"),
        ]
    }

    // MARK: - Sound Design

    private static func buildSoundDesigns() -> [SoundDesignSettings] {
        [
            SoundDesignSettings(
                sceneID: scene1_1ID,
                musicPrompt: "Subdued, pulsing tension. Low strings and distant electronic textures. Think 'Tinker Tailor Soldier Spy' score.",
                ambiencePrompt: "Quiet Vienna apartment at dusk. Distant street traffic, occasional tram bell, building settling sounds.",
                generatedMusicData: MockAudioGenerator.generateTone(frequency: 55, duration: 4.0),
                musicDuration: 45.0,
                musicIsLoopable: true
            ),
            SoundDesignSettings(
                sceneID: scene1_2ID,
                musicPrompt: "Urgent percussion, driving tempo. Pizzicato strings creating forward momentum.",
                ambiencePrompt: "Busy Vienna streets in evening. Footsteps, distant traffic, cafe chatter fading in and out."
            ),
            SoundDesignSettings(
                sceneID: scene2_2ID,
                musicPrompt: "Dark, minimal. Low drones with occasional metallic textures. Building dread.",
                ambiencePrompt: "Underground basement. Dripping water, creaking floorboards above, muffled voices.",
                generatedAmbienceData: MockAudioGenerator.generateAmbient(duration: 3.0),
                ambienceDuration: 120.0,
                ambienceIsLoopable: true
            ),
            SoundDesignSettings(
                sceneID: scene3_2ID,
                musicPrompt: "Chaotic, percussive, brass stabs. Think 'The Bourne Identity' climax.",
                ambiencePrompt: "Nighttime industrial area. Distant train horns, wind through structures, echo of gunfire."
            ),
        ]
    }

    // MARK: - Generation Jobs

    private static func buildGenerationJobs() -> [GenerationJob] {
        [
            // Completed job
            GenerationJob(
                id: GenerationJob.ID(),
                type: .epubImport,
                scope: .book,
                status: .completed,
                progress: 1.0,
                estimatedDuration: 12.0,
                createdAt: Date().addingTimeInterval(-3600),
                startedAt: Date().addingTimeInterval(-3600),
                completedAt: Date().addingTimeInterval(-3588),
                logMessages: [
                    "Parsing EPUB structure...",
                    "Extracting chapters...",
                    "Processing 3 chapters...",
                    "Import complete. 3 chapters, 10 scenes found."
                ]
            ),
            // In-progress job
            GenerationJob(
                id: GenerationJob.ID(),
                type: .sceneDetection,
                scope: .chapter,
                status: .running,
                progress: 0.45,
                estimatedDuration: 30.0,
                createdAt: Date().addingTimeInterval(-1800),
                startedAt: Date().addingTimeInterval(-1780),
                targetIDs: [chapter2ID.rawValue.uuidString],
                logMessages: [
                    "Loading model...",
                    "Analyzing Chapter 2: Safe House...",
                    "Detected 2 scene boundaries so far..."
                ]
            ),
            // Failed job
            GenerationJob(
                id: GenerationJob.ID(),
                type: .voiceGeneration,
                scope: .scene,
                status: .failed,
                progress: 0.23,
                estimatedDuration: 45.0,
                createdAt: Date().addingTimeInterval(-7200),
                startedAt: Date().addingTimeInterval(-7180),
                completedAt: Date().addingTimeInterval(-7135),
                errorMessage: "Voice model failed to load: weight file 'vocoder.safetensors' is corrupted. Try re-downloading the model.",
                targetIDs: [guardID.rawValue.uuidString],
                logMessages: [
                    "Loading voice model v2.1...",
                    "Generating voice profile for 'Unnamed Guard'...",
                    "ERROR: Weight checksum mismatch at offset 0x04F2A100"
                ]
            ),
            // Stale job (completed but upstream data changed)
            GenerationJob(
                id: GenerationJob.ID(),
                type: .dialogueAttribution,
                scope: .scene,
                status: .completed,
                progress: 1.0,
                createdAt: Date().addingTimeInterval(-5400),
                startedAt: Date().addingTimeInterval(-5390),
                completedAt: Date().addingTimeInterval(-5375),
                targetIDs: [scene2_4ID.rawValue.uuidString],
                logMessages: [
                    "Analyzing dialogue in 'The Betrayal'...",
                    "Attributed 2 blocks to known characters.",
                    "1 block could not be attributed (confidence < 0.5)."
                ]
            ),
            // Queued job
            GenerationJob(
                id: GenerationJob.ID(),
                type: .soundtrackGeneration,
                scope: .scene,
                status: .queued,
                progress: 0.0,
                estimatedDuration: 60.0,
                targetIDs: [scene3_1ID.rawValue.uuidString]
            ),
        ]
    }

    // MARK: - Review Issues

    private static func buildReviewIssues() -> [ReviewIssue] {
        [
            ReviewIssue(
                type: .uncertainSpeaker,
                title: "Unresolved speaker in 'The Chase'",
                description: "Block '\"Move. Now.\"' has no assigned speaker. The context suggests either Marcus or an unidentified third party. Review script context.",
                relatedStage: .script,
                relatedEntityID: "scene:\(scene1_2ID.rawValue.uuidString)",
                severity: .warning
            ),
            ReviewIssue(
                type: .uncertainSpeaker,
                title: "Ambiguous speaker in 'Kai's Discovery'",
                description: "Block '\"Can you break it?\"' could be spoken by Marcus or Elena. Neither character is currently present in this scene per the character list.",
                relatedStage: .script,
                relatedEntityID: "scene:\(scene2_3ID.rawValue.uuidString)",
                severity: .warning
            ),
            ReviewIssue(
                type: .uncertainSpeaker,
                title: "Unresolved speaker in 'Double Cross'",
                description: "Block '\"Kessler!\"' shouted across the train yard has no identified speaker. Context suggests Marcus or Kai.",
                relatedStage: .script,
                relatedEntityID: "scene:\(scene3_2ID.rawValue.uuidString)",
                severity: .info
            ),
            ReviewIssue(
                type: .duplicateCharacter,
                title: "Possible duplicate: Elena Vasquez / Dr. Helena Vance",
                description: "Dr. Helena Vance shares characteristics with Elena Vasquez (female, Vienna-based, intelligence background). The name 'Helena Vance' may be an alias. Both are listed as separate characters. Review and merge if confirmed.",
                relatedStage: .characters,
                relatedEntityID: "character:\(doctorAliasID.rawValue.uuidString)",
                severity: .warning
            ),
            ReviewIssue(
                type: .missingVoice,
                title: "No voice assigned for Unnamed Guard",
                description: "Character 'Unnamed Guard' has a nominated voice profile but the voice generation job failed. This character has 1 line in scene 2.2.",
                relatedStage: .voices,
                relatedEntityID: "character:\(guardID.rawValue.uuidString)",
                severity: .warning
            ),
            ReviewIssue(
                type: .failedGeneration,
                title: "Voice generation failed for Unnamed Guard",
                description: "Voice model reported a corrupted weight file. The job has been marked as failed. Try re-downloading the model and regenerating.",
                relatedStage: .voices,
                relatedEntityID: "character:\(guardID.rawValue.uuidString)",
                severity: .error
            ),
            ReviewIssue(
                type: .staleDialogue,
                title: "Stale dialogue attribution in 'The Betrayal'",
                description: "Dialogue was attributed before scene boundaries were adjusted in Chapter 2. Scene 2.4 may now include text that should have been attributed to Scene 2.3. Re-run attribution.",
                relatedStage: .script,
                relatedEntityID: "scene:\(scene2_4ID.rawValue.uuidString)",
                severity: .warning
            ),
            ReviewIssue(
                type: .abruptSceneTransition,
                title: "Low confidence scene boundary in 'The Betrayal'",
                description: "AI confidence for scene boundary between scenes 2.3 and 2.4 is only 68%. The transition may be incorrect. Review the boundary and consider adjusting.",
                relatedStage: .structure,
                relatedEntityID: "scene:\(scene2_4ID.rawValue.uuidString)",
                severity: .warning
            ),
            ReviewIssue(
                type: .exportValidation,
                title: "Export validation: 2 characters have no voice",
                description: "Characters 'Unnamed Guard' and 'Dr. Helena Vance' have no verified voice profile assigned. Export will fail unless these are resolved or characters are excluded.",
                relatedStage: .export,
                relatedEntityID: "project:\(projectID.rawValue.uuidString)",
                severity: .error
            ),
        ]
    }
}
