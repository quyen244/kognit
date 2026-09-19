import SwiftUI
import SwiftData
import UniformTypeIdentifiers

#if canImport(UIKit)
import UIKit
#endif

@Observable
@MainActor
public final class DocumentIngestionViewModel {
    public var activeTab: IngestionTab = .camera
    public var isPresentingScanner: Bool = false
    public var isPresentingFilePicker: Bool = false
    
    #if canImport(UIKit)
    public var scannedPages: [UIImage] = []
    #endif

    public var selectedFileName: String? = "AP_Bio_Cell_Respiration.pdf"
    public var selectedFileSize: String? = "4.2 MB"
    public var selectedFilePageCount: Int = 18
    public var selectedCourse: String = "AP Biology"
    public var selectedFilter: ScannerFilter = .bwHighContrast

    // Pipeline Execution State
    public var isProcessing: Bool = false
    public var currentStage: PipelineStage = .idle
    public var overallProgress: Double = 0.0
    public var stageProgress: [String: Double] = [:]
    public var estimatedSecondsRemaining: Int = 0
    public var errorMessage: String? = nil
    public var completedResult: IngestionSynthesisResult? = nil
    public var showCompletionAlert: Bool = false

    private var activeJobTask: Task<Void, Never>?

    public enum IngestionTab: String, CaseIterable, Sendable {
        case camera = "Camera Scanner"
        case filePicker = "PDF / PPTX Picker"
    }

    public enum ScannerFilter: String, CaseIterable, Sendable {
        case bwHighContrast = "B&W High-Contrast"
        case colorDoc = "Color Doc"
        case whiteboard = "Whiteboard"
    }

    public init() {}

    #if canImport(UIKit)
    public func addScannedPages(_ images: [UIImage]) {
        self.scannedPages.append(contentsOf: images)
    }

    public func clearScannedPages() {
        self.scannedPages.removeAll()
    }
    #endif

    // MARK: - Start Ingestion Pipeline
    public func startIngestionPipeline(modelContext: ModelContext) {
        guard !isProcessing else { return }

        isProcessing = true
        currentStage = .uploading
        overallProgress = 0.05
        errorMessage = nil

        let filename = selectedFileName ?? "Scanned_Note_\(Date().formatted(date: .numeric, time: .omitted)).pdf"
        let payload = DocumentPayload(
            filename: filename,
            fileType: filename.components(separatedBy: ".").last ?? "pdf",
            data: Data("Document Content".utf8),
            course: selectedCourse,
            pageCount: selectedFilePageCount
        )

        activeJobTask = Task {
            do {
                let jobResponse = try await KognitAPIClient.shared.uploadDocument(payload: payload)

                let result = try await KognitAPIClient.shared.pollJobStatus(jobId: jobResponse.jobId) { [weak self] update in
                    Task { @MainActor in
                        guard let self else { return }
                        self.currentStage = update.stage
                        self.overallProgress = update.progress
                        self.stageProgress = update.stageProgress
                        self.estimatedSecondsRemaining = update.estimatedSecondsRemaining
                    }
                }

                // Persist synthesized results into SwiftData
                self.persistSynthesisResult(result, payload: payload, modelContext: modelContext)

                self.completedResult = result
                self.currentStage = .complete
                self.overallProgress = 1.0
                self.isProcessing = false
                self.showCompletionAlert = true

            } catch {
                self.currentStage = .failed
                self.errorMessage = error.localizedDescription
                self.isProcessing = false
            }
        }
    }

    public func cancelIngestion() {
        activeJobTask?.cancel()
        activeJobTask = nil
        isProcessing = false
        currentStage = .idle
        overallProgress = 0.0
    }

    // MARK: - Persist to SwiftData
    private func persistSynthesisResult(
        _ result: IngestionSynthesisResult,
        payload: DocumentPayload,
        modelContext: ModelContext
    ) {
        let docEntity = DocumentEntity(
            filename: payload.filename,
            fileType: payload.fileType,
            rawText: "Synthesized AP Course Material",
            course: payload.course,
            pageCount: payload.pageCount,
            isProcessed: true
        )
        modelContext.insert(docEntity)

        // Slide Deck
        let deck = SlideDeckEntity(title: "\(payload.course) - \(result.documentTitle)", course: payload.course)
        deck.document = docEntity
        modelContext.insert(deck)

        for s in result.slides {
            let slide = SlideEntity(
                slideIndex: s.slideIndex,
                slideIdTag: s.slideIdTag,
                slideType: s.slideType,
                title: s.title,
                summary: s.summary,
                bulletPoints: s.bulletPoints,
                apExamTrap: s.apExamTrap,
                equationString: s.equationString
            )
            slide.deck = deck
            modelContext.insert(slide)

            for term in s.formulaTerms {
                let termEntity = FormulaTermEntity(
                    symbol: term.symbol,
                    name: term.name,
                    explanation: term.explanation,
                    colorHex: term.colorHex
                )
                termEntity.slide = slide
                modelContext.insert(termEntity)
            }
        }

        // Flashcards
        for (idx, c) in result.flashcards.enumerated() {
            let card = FlashcardEntity(
                front: c.front,
                back: c.back,
                explanation: c.explanation,
                hint: c.hint,
                unitTag: c.unitTag,
                cardIndex: idx + 1
            )
            card.document = docEntity
            modelContext.insert(card)
        }

        // Exam Questions
        if !result.examQuestions.isEmpty {
            let exam = ExamEntity(
                title: "\(payload.course) Synthesized Diagnostic Exam",
                course: payload.course,
                standard: .ap,
                timeLimitSeconds: 15 * 60
            )
            exam.document = docEntity
            modelContext.insert(exam)

            for q in result.examQuestions {
                let questionEntity = ExamQuestionEntity(
                    questionIndex: q.questionIndex,
                    questionType: q.questionType,
                    prompt: q.prompt,
                    stimulusText: q.stimulusText,
                    maxPoints: q.maxPoints
                )
                questionEntity.exam = exam
                modelContext.insert(questionEntity)

                for opt in q.options {
                    let optEntity = OptionEntity(
                        letter: opt.letter,
                        text: opt.text,
                        isCorrect: opt.isCorrect,
                        distractorRationale: opt.distractorRationale
                    )
                    optEntity.question = questionEntity
                    modelContext.insert(optEntity)
                }

                for rub in q.rubricPoints {
                    let rubEntity = RubricPointEntity(
                        pointNumber: rub.pointNumber,
                        criteriaTitle: rub.criteriaTitle,
                        requirementDescription: rub.requirementDescription
                    )
                    rubEntity.question = questionEntity
                    modelContext.insert(rubEntity)
                }
            }
        }

        try? modelContext.save()
    }
}
