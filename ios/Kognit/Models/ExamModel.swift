import Foundation
import SwiftData

// MARK: - Exam Standard
public enum ExamStandard: String, Codable, CaseIterable, Sendable {
    case ap = "AP Standard (1-5 Scale)"
    case sat = "SAT Standard (200-800 Scale)"
    
    public var shortCode: String {
        switch self {
        case .ap: return "AP"
        case .sat: return "SAT"
        }
    }
}

// MARK: - Question Type
public enum QuestionType: String, Codable, CaseIterable, Sendable {
    case mcq = "Multiple Choice (MCQ)"
    case frq = "Free Response (FRQ)"
}

// MARK: - SwiftData Option Entity (for MCQ)
@Model
public final class OptionEntity {
    @Attribute(.unique) public var id: UUID
    public var letter: String // "A", "B", "C", "D"
    public var text: String
    public var isCorrect: Bool
    public var distractorRationale: String

    public var question: ExamQuestionEntity?

    public init(
        id: UUID = UUID(),
        letter: String,
        text: String,
        isCorrect: Bool,
        distractorRationale: String
    ) {
        self.id = id
        self.letter = letter
        self.text = text
        self.isCorrect = isCorrect
        self.distractorRationale = distractorRationale
    }
}

// MARK: - SwiftData Rubric Point Entity (for FRQ)
@Model
public final class RubricPointEntity {
    @Attribute(.unique) public var id: UUID
    public var pointNumber: Int
    public var criteriaTitle: String
    public var requirementDescription: String
    public var isEarned: Bool

    public var question: ExamQuestionEntity?

    public init(
        id: UUID = UUID(),
        pointNumber: Int,
        criteriaTitle: String,
        requirementDescription: String,
        isEarned: Bool = false
    ) {
        self.id = id
        self.pointNumber = pointNumber
        self.criteriaTitle = criteriaTitle
        self.requirementDescription = requirementDescription
        self.isEarned = isEarned
    }
}

// MARK: - SwiftData Exam Question Entity
@Model
public final class ExamQuestionEntity {
    @Attribute(.unique) public var id: UUID
    public var questionIndex: Int
    public var questionTypeRaw: String
    public var prompt: String
    public var stimulusText: String?
    public var stimulusTag: String?
    public var maxPoints: Int
    public var earnedPoints: Int
    public var studentAnswerText: String?
    public var selectedOptionId: UUID?
    public var isAnswered: Bool

    @Relationship(deleteRule: .cascade, inverse: \OptionEntity.question)
    public var options: [OptionEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \RubricPointEntity.question)
    public var rubricPoints: [RubricPointEntity] = []

    public var exam: ExamEntity?

    public var questionType: QuestionType {
        get { QuestionType(rawValue: questionTypeRaw) ?? .mcq }
        set { questionTypeRaw = newValue.rawValue }
    }

    public var isCorrectMCQ: Bool {
        guard questionType == .mcq, let selectedId = selectedOptionId else { return false }
        return options.first(where: { $0.id == selectedId })?.isCorrect == true
    }

    public init(
        id: UUID = UUID(),
        questionIndex: Int,
        questionType: QuestionType = .mcq,
        prompt: String,
        stimulusText: String? = nil,
        stimulusTag: String? = "Stimulus-Based",
        maxPoints: Int = 1,
        earnedPoints: Int = 0,
        studentAnswerText: String? = nil,
        selectedOptionId: UUID? = nil,
        isAnswered: Bool = false
    ) {
        self.id = id
        self.questionIndex = questionIndex
        self.questionTypeRaw = questionType.rawValue
        self.prompt = prompt
        self.stimulusText = stimulusText
        self.stimulusTag = stimulusTag
        self.maxPoints = maxPoints
        self.earnedPoints = earnedPoints
        self.studentAnswerText = studentAnswerText
        self.selectedOptionId = selectedOptionId
        self.isAnswered = isAnswered
    }
}

// MARK: - SwiftData Exam Result Entity
@Model
public final class ExamResultEntity {
    @Attribute(.unique) public var id: UUID
    public var totalPointsEarned: Int
    public var totalPointsPossible: Int
    public var scaledScoreDisplay: String // e.g. "4.4 / 5.0" (AP) or "720 / 800" (SAT)
    public var percentageScore: Double
    public var durationSeconds: Int
    public var completedAt: Date

    public var exam: ExamEntity?

    public init(
        id: UUID = UUID(),
        totalPointsEarned: Int,
        totalPointsPossible: Int,
        scaledScoreDisplay: String,
        percentageScore: Double,
        durationSeconds: Int,
        completedAt: Date = Date()
    ) {
        self.id = id
        self.totalPointsEarned = totalPointsEarned
        self.totalPointsPossible = totalPointsPossible
        self.scaledScoreDisplay = scaledScoreDisplay
        self.percentageScore = percentageScore
        self.durationSeconds = durationSeconds
        self.completedAt = completedAt
    }
}

// MARK: - SwiftData Exam Entity
@Model
public final class ExamEntity {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var course: String
    public var standardRaw: String
    public var timeLimitSeconds: Int
    public var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ExamQuestionEntity.exam)
    public var questions: [ExamQuestionEntity] = []

    @Relationship(deleteRule: .cascade, inverse: \ExamResultEntity.exam)
    public var results: [ExamResultEntity] = []

    public var document: DocumentEntity?

    public var standard: ExamStandard {
        get { ExamStandard(rawValue: standardRaw) ?? .ap }
        set { standardRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        title: String,
        course: String = "AP Biology",
        standard: ExamStandard = .ap,
        timeLimitSeconds: Int = 15 * 60, // 15 minutes default
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.course = course
        self.standardRaw = standard.rawValue
        self.timeLimitSeconds = timeLimitSeconds
        self.createdAt = createdAt
    }
}
