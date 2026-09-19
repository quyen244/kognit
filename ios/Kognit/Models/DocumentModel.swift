import Foundation
import SwiftData

// MARK: - Pipeline Stage Enum
public enum PipelineStage: String, CaseIterable, Codable, Sendable {
    case idle = "Ready"
    case uploading = "Uploading to Cloud..."
    case ocr = "Vision OCR & MathPix Extraction..."
    case chunking = "Semantic Chunking & Embedding..."
    case synthesizing = "Generating Slides & Flashcards..."
    case complete = "Ready to Study!"
    case failed = "Processing Failed"

    public var stepNumber: Int {
        switch self {
        case .idle: return 0
        case .uploading: return 1
        case .ocr: return 2
        case .chunking: return 3
        case .synthesizing: return 4
        case .complete: return 5
        case .failed: return -1
        }
    }

    public var systemImage: String {
        switch self {
        case .idle: return "doc.badge.plus"
        case .uploading: return "icloud.and.arrow.up"
        case .ocr: return "text.viewfinder"
        case .chunking: return "point.3.filled.connected.trianglepath.dotted"
        case .synthesizing: return "sparkles"
        case .complete: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    public var isTerminal: Bool {
        self == .complete || self == .failed
    }
}

// MARK: - Document Payload for Upload
public struct DocumentPayload: Sendable {
    public let id: UUID
    public let filename: String
    public let fileType: String
    public let data: Data
    public let course: String
    public let pageCount: Int

    public init(
        id: UUID = UUID(),
        filename: String,
        fileType: String,
        data: Data,
        course: String = "AP Biology",
        pageCount: Int = 1
    ) {
        self.id = id
        self.filename = filename
        self.fileType = fileType
        self.data = data
        self.course = course
        self.pageCount = pageCount
    }
}

// MARK: - Ingestion Job Response
public struct IngestionJobResponse: Codable, Sendable {
    public let jobId: String
    public let status: String
    public let estimatedSecondsRemaining: Int
    public let message: String?

    public init(jobId: String, status: String, estimatedSecondsRemaining: Int, message: String? = nil) {
        self.jobId = jobId
        self.status = status
        self.estimatedSecondsRemaining = estimatedSecondsRemaining
        self.message = message
    }
}

// MARK: - Job Status Update
public struct JobStatusUpdate: Codable, Sendable {
    public let jobId: String
    public let stage: PipelineStage
    public let progress: Double // 0.0 to 1.0
    public let stageProgress: [String: Double]
    public let estimatedSecondsRemaining: Int
    public let error: String?

    public init(
        jobId: String,
        stage: PipelineStage,
        progress: Double,
        stageProgress: [String: Double] = [:],
        estimatedSecondsRemaining: Int = 0,
        error: String? = nil
    ) {
        self.jobId = jobId
        self.stage = stage
        self.progress = progress
        self.stageProgress = stageProgress
        self.estimatedSecondsRemaining = estimatedSecondsRemaining
        self.error = error
    }
}

// MARK: - SwiftData Document Entity
@Model
public final class DocumentEntity {
    @Attribute(.unique) public var id: UUID
    public var filename: String
    public var fileType: String
    public var rawText: String
    public var course: String
    public var pageCount: Int
    public var createdAt: Date
    public var isProcessed: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \SlideDeckEntity.document)
    public var slideDeck: SlideDeckEntity?
    
    @Relationship(deleteRule: .cascade, inverse: \FlashcardEntity.document)
    public var flashcards: [FlashcardEntity] = []
    
    @Relationship(deleteRule: .cascade, inverse: \ExamEntity.document)
    public var exams: [ExamEntity] = []

    public init(
        id: UUID = UUID(),
        filename: String,
        fileType: String,
        rawText: String = "",
        course: String = "AP Biology",
        pageCount: Int = 1,
        createdAt: Date = Date(),
        isProcessed: Bool = false
    ) {
        self.id = id
        self.filename = filename
        self.fileType = fileType
        self.rawText = rawText
        self.course = course
        self.pageCount = pageCount
        self.createdAt = createdAt
        self.isProcessed = isProcessed
    }
}
