import Foundation
import SwiftData

// MARK: - FSRS Rating Enum
public enum FSRSRating: Int, Codable, CaseIterable, Sendable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4

    public var title: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }

    public var defaultIntervalLabel: String {
        switch self {
        case .again: return "< 10m"
        case .hard: return "12h"
        case .good: return "1d"
        case .easy: return "4d"
        }
    }

    public var colorHex: String {
        switch self {
        case .again: return "#EF4444" // red
        case .hard: return "#F59E0B"  // amber
        case .good: return "#10B981"  // green
        case .easy: return "#3B82F6"  // blue
        }
    }
}

// MARK: - Flashcard State in Spaced Repetition Lifecycle
public enum CardRepetitionState: String, Codable, Sendable {
    case new = "New"
    case learning = "Learning"
    case review = "Review"
    case relearning = "Relearning"
}

// MARK: - FSRS State Snapshot
public struct FSRSState: Codable, Sendable {
    public var stability: Double
    public var difficulty: Double
    public var repetitions: Int
    public var lapses: Int
    public var state: CardRepetitionState
    public var lastReviewDate: Date?
    public var nextReviewDate: Date

    public init(
        stability: Double = 1.0,
        difficulty: Double = 5.0,
        repetitions: Int = 0,
        lapses: Int = 0,
        state: CardRepetitionState = .new,
        lastReviewDate: Date? = nil,
        nextReviewDate: Date = Date()
    ) {
        self.stability = stability
        self.difficulty = difficulty
        self.repetitions = repetitions
        self.lapses = lapses
        self.state = state
        self.lastReviewDate = lastReviewDate
        self.nextReviewDate = nextReviewDate
    }
}

// MARK: - SwiftData Flashcard Entity
@Model
public final class FlashcardEntity {
    @Attribute(.unique) public var id: UUID
    public var front: String
    public var back: String
    public var explanation: String
    public var hint: String?
    public var unitTag: String
    public var cardIndex: Int
    public var createdAt: Date

    // FSRS 4.5 Parameters
    public var stability: Double
    public var difficulty: Double
    public var repetitions: Int
    public var lapses: Int
    public var stateRaw: String
    public var lastReviewDate: Date?
    public var nextReviewDate: Date

    // Relationship to parent document
    public var document: DocumentEntity?

    public var state: CardRepetitionState {
        get { CardRepetitionState(rawValue: stateRaw) ?? .new }
        set { stateRaw = newValue.rawValue }
    }

    public var isDue: Bool {
        Date() >= nextReviewDate
    }

    public init(
        id: UUID = UUID(),
        front: String,
        back: String,
        explanation: String = "",
        hint: String? = nil,
        unitTag: String = "AP Bio Unit 3",
        cardIndex: Int = 1,
        stability: Double = 1.0,
        difficulty: Double = 5.0,
        repetitions: Int = 0,
        lapses: Int = 0,
        state: CardRepetitionState = .new,
        lastReviewDate: Date? = nil,
        nextReviewDate: Date = Date(),
        createdAt: Date = Date()
    ) {
        self.id = id
        self.front = front
        self.back = back
        self.explanation = explanation
        self.hint = hint
        self.unitTag = unitTag
        self.cardIndex = cardIndex
        self.stability = stability
        self.difficulty = difficulty
        self.repetitions = repetitions
        self.lapses = lapses
        self.stateRaw = state.rawValue
        self.lastReviewDate = lastReviewDate
        self.nextReviewDate = nextReviewDate
        self.createdAt = createdAt
    }

    public func snapshotFSRSState() -> FSRSState {
        FSRSState(
            stability: stability,
            difficulty: difficulty,
            repetitions: repetitions,
            lapses: lapses,
            state: state,
            lastReviewDate: lastReviewDate,
            nextReviewDate: nextReviewDate
        )
    }

    public func applyFSRSState(_ newState: FSRSState) {
        self.stability = newState.stability
        self.difficulty = newState.difficulty
        self.repetitions = newState.repetitions
        self.lapses = newState.lapses
        self.state = newState.state
        self.lastReviewDate = newState.lastReviewDate
        self.nextReviewDate = newState.nextReviewDate
    }
}
