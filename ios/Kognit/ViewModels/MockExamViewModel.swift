import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

@Observable
@MainActor
public final class MockExamViewModel {
    public var exam: ExamEntity?
    public var questions: [ExamQuestionEntity] = []
    public var currentIndex: Int = 0
    public var activeSection: QuestionType = .mcq
    public var remainingSeconds: Int = 15 * 60 // 15 mins default
    public var isTimerRunning: Bool = false
    public var examSubmitted: Bool = false
    public var examResult: ExamResultEntity? = nil

    // FRQ state for active question
    public var frqStudentInput: String = ""
    public var frqRubricEvaluated: Bool = false

    private var timerTask: Task<Void, Never>?

    public var currentQuestion: ExamQuestionEntity? {
        guard !filteredQuestions.isEmpty, currentIndex >= 0, currentIndex < filteredQuestions.count else { return nil }
        return filteredQuestions[currentIndex]
    }

    public var filteredQuestions: [ExamQuestionEntity] {
        questions.filter { $0.questionType == activeSection }
    }

    public var formattedTimer: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    public var isTimerWarning: Bool {
        remainingSeconds <= 120 // Under 2 minutes
    }

    public init(exam: ExamEntity? = nil) {
        self.exam = exam
        if let exam = exam {
            self.questions = exam.questions.sorted { $0.questionIndex < $1.questionIndex }
            self.remainingSeconds = exam.timeLimitSeconds
        }
    }

    public func setExam(_ exam: ExamEntity) {
        self.exam = exam
        self.questions = exam.questions.sorted { $0.questionIndex < $1.questionIndex }
        self.remainingSeconds = exam.timeLimitSeconds
        self.currentIndex = 0
        self.activeSection = .mcq
        self.examSubmitted = false
        self.examResult = nil
        self.frqStudentInput = ""
        self.frqRubricEvaluated = false
        startTimer()
    }

    // MARK: - Timer Controls
    public func startTimer() {
        guard !isTimerRunning else { return }
        isTimerRunning = true

        timerTask = Task {
            while !Task.isCancelled && self.remainingSeconds > 0 && self.isTimerRunning {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                if !self.isTimerRunning { break }
                self.remainingSeconds -= 1
                if self.remainingSeconds == 0 {
                    self.submitExam()
                    break
                }
            }
        }
    }

    public func pauseTimer() {
        isTimerRunning = false
        timerTask?.cancel()
        timerTask = nil
    }

    // MARK: - Section Switch
    public func switchSection(_ section: QuestionType) {
        self.activeSection = section
        self.currentIndex = 0
        self.frqRubricEvaluated = false
        self.frqStudentInput = currentQuestion?.studentAnswerText ?? ""
    }

    // MARK: - MCQ Selection
    public func selectOption(_ option: OptionEntity, modelContext: ModelContext) {
        guard let question = currentQuestion, question.questionType == .mcq else { return }
        question.selectedOptionId = option.id
        question.isAnswered = true
        question.earnedPoints = option.isCorrect ? question.maxPoints : 0

        #if canImport(UIKit)
        if option.isCorrect {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
        #endif

        try? modelContext.save()
    }

    // MARK: - FRQ Evaluation
    public func evaluateFRQ(modelContext: ModelContext) {
        guard let question = currentQuestion, question.questionType == .frq else { return }
        guard !frqStudentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        question.studentAnswerText = frqStudentInput
        question.isAnswered = true

        // Simulate AP Rubric matching based on input keywords
        let lower = frqStudentInput.lowercased()
        var earnedPoints = 0

        for rubricPoint in question.rubricPoints {
            // Check semantic matches for AP bio prompt
            let matches: Bool
            switch rubricPoint.pointNumber {
            case 1:
                matches = lower.contains("increase") || lower.contains("high") || lower.contains("greater") || lower.contains("steep")
            case 2:
                matches = lower.contains("matrix") || lower.contains("flow") || lower.contains("gradient") || lower.contains("block") || lower.contains("cannot")
            case 3:
                matches = lower.contains("etc") || lower.contains("pump") || lower.contains("electron") || lower.contains("chain") || lower.contains("backpressure")
            case 4:
                matches = lower.contains("atp") || lower.contains("synth") || lower.contains("stop") || lower.contains("zero") || lower.contains("inhibit")
            default:
                matches = true
            }

            rubricPoint.isEarned = matches
            if matches {
                earnedPoints += 1
            }
        }

        question.earnedPoints = earnedPoints
        frqRubricEvaluated = true

        #if canImport(UIKit)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif

        try? modelContext.save()
    }

    // MARK: - Submit & Score Exam
    public func submitExam() {
        pauseTimer()
        examSubmitted = true

        var totalEarned = 0
        var totalPossible = 0

        for q in questions {
            totalEarned += q.earnedPoints
            totalPossible += q.maxPoints
        }

        let percentage = totalPossible > 0 ? (Double(totalEarned) / Double(totalPossible)) * 100.0 : 0.0

        let scaledScore: String
        let standard = exam?.standard ?? .ap

        switch standard {
        case .ap:
            // AP 1-5 scale
            let apScore: Double
            if percentage >= 80 { apScore = 5.0 }
            else if percentage >= 68 { apScore = 4.4 }
            else if percentage >= 55 { apScore = 3.6 }
            else if percentage >= 40 { apScore = 2.8 }
            else { apScore = 1.5 }
            scaledScore = String(format: "%.1f / 5.0", apScore)

        case .sat:
            // SAT 200-800 scale
            let satScore = Int(200.0 + (percentage / 100.0) * 600.0)
            scaledScore = "\(satScore) / 800"
        }

        let duration = (exam?.timeLimitSeconds ?? 900) - remainingSeconds

        self.examResult = ExamResultEntity(
            totalPointsEarned: totalEarned,
            totalPointsPossible: totalPossible,
            scaledScoreDisplay: scaledScore,
            percentageScore: percentage,
            durationSeconds: duration
        )
    }

    public func restartExam() {
        for q in questions {
            q.isAnswered = false
            q.selectedOptionId = nil
            q.studentAnswerText = nil
            q.earnedPoints = 0
            for r in q.rubricPoints {
                r.isEarned = false
            }
        }
        remainingSeconds = exam?.timeLimitSeconds ?? (15 * 60)
        examSubmitted = false
        examResult = nil
        frqStudentInput = ""
        frqRubricEvaluated = false
        currentIndex = 0
        startTimer()
    }
}
