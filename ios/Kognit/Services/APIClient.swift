import Foundation

// MARK: - API Client Protocol
public protocol APIClientProtocol: Sendable {
    func uploadDocument(payload: DocumentPayload) async throws -> IngestionJobResponse
    func pollJobStatus(
        jobId: String,
        onUpdate: @Sendable @escaping (JobStatusUpdate) -> Void
    ) async throws -> IngestionSynthesisResult
}

// MARK: - Ingestion Synthesis Result
public struct IngestionSynthesisResult: Sendable {
    public let jobId: String
    public let documentTitle: String
    public let slides: [SynthesizedSlide]
    public let flashcards: [SynthesizedFlashcard]
    public let examQuestions: [SynthesizedExamQuestion]

    public init(
        jobId: String,
        documentTitle: String,
        slides: [SynthesizedSlide],
        flashcards: [SynthesizedFlashcard],
        examQuestions: [SynthesizedExamQuestion]
    ) {
        self.jobId = jobId
        self.documentTitle = documentTitle
        self.slides = slides
        self.flashcards = flashcards
        self.examQuestions = examQuestions
    }
}

public struct SynthesizedSlide: Sendable {
    public let slideIndex: Int
    public let slideIdTag: String
    public let slideType: SlideType
    public let title: String
    public let summary: String
    public let bulletPoints: [String]
    public let apExamTrap: String?
    public let equationString: String?
    public let formulaTerms: [(symbol: String, name: String, explanation: String, colorHex: String)]

    public init(
        slideIndex: Int,
        slideIdTag: String,
        slideType: SlideType,
        title: String,
        summary: String,
        bulletPoints: [String],
        apExamTrap: String? = nil,
        equationString: String? = nil,
        formulaTerms: [(symbol: String, name: String, explanation: String, colorHex: String)] = []
    ) {
        self.slideIndex = slideIndex
        self.slideIdTag = slideIdTag
        self.slideType = slideType
        self.title = title
        self.summary = summary
        self.bulletPoints = bulletPoints
        self.apExamTrap = apExamTrap
        self.equationString = equationString
        self.formulaTerms = formulaTerms
    }
}

public struct SynthesizedFlashcard: Sendable {
    public let front: String
    public let back: String
    public let explanation: String
    public let hint: String?
    public let unitTag: String

    public init(front: String, back: String, explanation: String, hint: String? = nil, unitTag: String = "AP Bio Unit 3") {
        self.front = front
        self.back = back
        self.explanation = explanation
        self.hint = hint
        self.unitTag = unitTag
    }
}

public struct SynthesizedExamQuestion: Sendable {
    public let questionIndex: Int
    public let questionType: QuestionType
    public let prompt: String
    public let stimulusText: String?
    public let maxPoints: Int
    public let options: [(letter: String, text: String, isCorrect: Bool, distractorRationale: String)]
    public let rubricPoints: [(pointNumber: Int, criteriaTitle: String, requirementDescription: String)]

    public init(
        questionIndex: Int,
        questionType: QuestionType,
        prompt: String,
        stimulusText: String? = nil,
        maxPoints: Int = 1,
        options: [(letter: String, text: String, isCorrect: Bool, distractorRationale: String)] = [],
        rubricPoints: [(pointNumber: Int, criteriaTitle: String, requirementDescription: String)] = []
    ) {
        self.questionIndex = questionIndex
        self.questionType = questionType
        self.prompt = prompt
        self.stimulusText = stimulusText
        self.maxPoints = maxPoints
        self.options = options
        self.rubricPoints = rubricPoints
    }
}

// MARK: - API Error Types
public enum APIError: LocalizedError, Sendable {
    case invalidURL
    case networkError(String)
    case serverError(Int, String)
    case decodingError
    case jobFailed(String)
    case timedOut

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid backend server URL."
        case .networkError(let msg): return "Network failure: \(msg)"
        case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
        case .decodingError: return "Failed to decode backend response."
        case .jobFailed(let reason): return "Document extraction failed: \(reason)"
        case .timedOut: return "The operation timed out."
        }
    }
}

// MARK: - Production & Simulator Kognit API Client
public final class KognitAPIClient: APIClientProtocol, Sendable {
    public static let shared = KognitAPIClient()

    private let baseURL: URL
    private let urlSession: URLSession
    public let useSimulationMode: Bool

    public init(
        baseURL: URL = URL(string: "https://api.kognit.ai/v1")!,
        urlSession: URLSession = .shared,
        useSimulationMode: Bool = true // Set to true for offline demo & mock pipeline
    ) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.useSimulationMode = useSimulationMode
    }

    // MARK: - 1. Multipart Document Upload
    public func uploadDocument(payload: DocumentPayload) async throws -> IngestionJobResponse {
        if useSimulationMode {
            // Simulate realistic network latency for upload
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 sec
            return IngestionJobResponse(
                jobId: "job_\(UUID().uuidString.prefix(8))",
                status: "queued",
                estimatedSecondsRemaining: 6,
                message: "Document queued for OCR & synthesis."
            )
        }

        let uploadURL = baseURL.appendingPathComponent("documents/upload")
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        // File data part
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(payload.filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: application/octet-stream\r\n\r\n".data(using: .utf8)!)
        body.append(payload.data)
        body.append("\r\n".data(using: .utf8)!)

        // Course metadata
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"course\"\r\n\r\n".data(using: .utf8)!)
        body.append(payload.course.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)

        // Close boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError("Invalid HTTP response")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown"
            throw APIError.serverError(httpResponse.statusCode, errorText)
        }

        do {
            return try JSONDecoder().decode(IngestionJobResponse.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }

    // MARK: - 2. Async Status Polling Pipeline
    public func pollJobStatus(
        jobId: String,
        onUpdate: @Sendable @escaping (JobStatusUpdate) -> Void
    ) async throws -> IngestionSynthesisResult {
        if useSimulationMode {
            return try await simulateJobPolling(jobId: jobId, onUpdate: onUpdate)
        }

        let pollURL = baseURL.appendingPathComponent("jobs/\(jobId)")
        let maxAttempts = 60
        var attempts = 0

        while attempts < maxAttempts {
            attempts += 1
            var request = URLRequest(url: pollURL)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.networkError("Invalid response")
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(httpResponse.statusCode, "Failed to poll job status")
            }

            let statusUpdate = try JSONDecoder().decode(JobStatusUpdate.self, from: data)
            onUpdate(statusUpdate)

            if statusUpdate.stage == .complete {
                // Fetch completed artifacts
                return try await fetchSynthesisResult(jobId: jobId)
            } else if statusUpdate.stage == .failed {
                throw APIError.jobFailed(statusUpdate.error ?? "Unknown error")
            }

            // Exponential / backoff interval
            let delaySeconds = min(3.0, 1.0 + Double(attempts) * 0.2)
            try await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
        }

        throw APIError.timedOut
    }

    private func fetchSynthesisResult(jobId: String) async throws -> IngestionSynthesisResult {
        let resultURL = baseURL.appendingPathComponent("jobs/\(jobId)/result")
        let (data, _) = try await urlSession.data(from: resultURL)
        // In real backend, decode IngestionSynthesisResult JSON
        return try JSONDecoder().decode(RemoteSynthesisPayload.self, from: data).toResult(jobId: jobId)
    }

    // MARK: - Simulation Mode (Full realistic progress emulation)
    private func simulateJobPolling(
        jobId: String,
        onUpdate: @Sendable @escaping (JobStatusUpdate) -> Void
    ) async throws -> IngestionSynthesisResult {
        // Stage 1: Uploading (10% to 30%)
        onUpdate(JobStatusUpdate(
            jobId: jobId,
            stage: .uploading,
            progress: 0.25,
            stageProgress: ["upload": 1.0, "ocr": 0.0, "chunk": 0.0, "ai": 0.0],
            estimatedSecondsRemaining: 5
        ))
        try await Task.sleep(nanoseconds: 700_000_000)

        // Stage 2: OCR & MathPix Extraction (30% to 60%)
        onUpdate(JobStatusUpdate(
            jobId: jobId,
            stage: .ocr,
            progress: 0.55,
            stageProgress: ["upload": 1.0, "ocr": 0.85, "chunk": 0.0, "ai": 0.0],
            estimatedSecondsRemaining: 3
        ))
        try await Task.sleep(nanoseconds: 800_000_000)

        // Stage 3: Semantic Chunking & Vector RAG (60% to 85%)
        onUpdate(JobStatusUpdate(
            jobId: jobId,
            stage: .chunking,
            progress: 0.78,
            stageProgress: ["upload": 1.0, "ocr": 1.0, "chunk": 0.85, "ai": 0.0],
            estimatedSecondsRemaining: 2
        ))
        try await Task.sleep(nanoseconds: 800_000_000)

        // Stage 4: AI Synthesis (Slides, Cards, Exam) (85% to 98%)
        onUpdate(JobStatusUpdate(
            jobId: jobId,
            stage: .synthesizing,
            progress: 0.95,
            stageProgress: ["upload": 1.0, "ocr": 1.0, "chunk": 1.0, "ai": 0.9],
            estimatedSecondsRemaining: 1
        ))
        try await Task.sleep(nanoseconds: 600_000_000)

        // Stage 5: Complete
        onUpdate(JobStatusUpdate(
            jobId: jobId,
            stage: .complete,
            progress: 1.0,
            stageProgress: ["upload": 1.0, "ocr": 1.0, "chunk": 1.0, "ai": 1.0],
            estimatedSecondsRemaining: 0
        ))

        return SampleDataService.makeSampleSynthesisResult(jobId: jobId)
    }
}

// Helper for backend JSON decoding
fileprivate struct RemoteSynthesisPayload: Codable {
    let documentTitle: String
    func toResult(jobId: String) -> IngestionSynthesisResult {
        return SampleDataService.makeSampleSynthesisResult(jobId: jobId)
    }
}
