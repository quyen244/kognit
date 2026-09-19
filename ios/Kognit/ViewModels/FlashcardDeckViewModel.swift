import SwiftUI
import SwiftData

#if canImport(UIKit)
import UIKit
#endif

@Observable
@MainActor
public final class FlashcardDeckViewModel {
    public var cards: [FlashcardEntity] = []
    public var currentIndex: Int = 0
    public var isFlipped: Bool = false
    public var sessionComplete: Bool = false
    public var ratingsGiven: [UUID: FSRSRating] = [:]

    public var currentCard: FlashcardEntity? {
        guard !cards.isEmpty, currentIndex >= 0, currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    public var progress: Double {
        guard !cards.isEmpty else { return 0.0 }
        return Double(currentIndex) / Double(cards.count)
    }

    public var progressText: String {
        guard !cards.isEmpty else { return "0 of 0" }
        return "Card \(currentIndex + 1) of \(cards.count)"
    }

    public init(cards: [FlashcardEntity] = []) {
        self.cards = cards
    }

    public func setCards(_ newCards: [FlashcardEntity]) {
        self.cards = newCards
        self.currentIndex = 0
        self.isFlipped = false
        self.sessionComplete = false
        self.ratingsGiven.removeAll()
    }

    // MARK: - 3D Card Flip
    public func flipCard() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            isFlipped.toggle()
        }
        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
    }

    // MARK: - Interval Label Preview for Button
    public func intervalLabel(for rating: FSRSRating) -> String {
        guard let card = currentCard else { return rating.defaultIntervalLabel }
        let snapshot = card.snapshotFSRSState()
        return FSRSScheduler.shared.intervalPreview(for: rating, currentState: snapshot)
    }

    // MARK: - Rate Current Card with FSRS-4.5
    public func rateCard(_ rating: FSRSRating, modelContext: ModelContext) {
        guard let card = currentCard else { return }

        #if canImport(UIKit)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        #endif

        ratingsGiven[card.id] = rating

        // Calculate next state using FSRS-4.5
        let currentSnapshot = card.snapshotFSRSState()
        let nextFSRSState = FSRSScheduler.shared.review(currentState: currentSnapshot, rating: rating)
        card.applyFSRSState(nextFSRSState)

        try? modelContext.save()

        // Flip back to front
        withAnimation(.easeOut(duration: 0.2)) {
            isFlipped = false
        }

        // Advance to next card with slight delay for smooth transition
        Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            if self.currentIndex + 1 < self.cards.count {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.currentIndex += 1
                }
            } else {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.sessionComplete = true
                }
                #if canImport(UIKit)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
            }
        }
    }

    public func restartSession() {
        currentIndex = 0
        isFlipped = false
        sessionComplete = false
        ratingsGiven.removeAll()
    }
}
