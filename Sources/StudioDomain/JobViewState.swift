import Foundation

/// Display model for a generation job in the UI.
public struct JobViewState: Identifiable, Sendable {
    public let id: GenerationJob.ID
    public var name: String
    public var type: JobType
    public var status: JobStatus
    public var progress: Double
    public var estimatedDuration: String
    public var scope: GenerationScope
    public var logLines: [String]

    public init(
        job: GenerationJob,
        name: String? = nil
    ) {
        self.id = job.id
        self.name = name ?? job.type.rawValue
        self.type = job.type
        self.status = job.status
        self.progress = job.progress
        self.scope = job.scope
        self.logLines = job.logMessages

        if let duration = job.estimatedDuration {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            self.estimatedDuration = "\(minutes)m \(seconds)s"
        } else {
            self.estimatedDuration = "Unknown"
        }
    }
}
