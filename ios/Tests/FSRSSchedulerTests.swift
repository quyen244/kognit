import Testing
import Foundation
@testable import Kognit

@Suite("FSRS-4.5 Scheduler Tests")
struct FSRSSchedulerTests {
    let scheduler = FSRSScheduler.shared

    @Test("Initial Review Stability for Each Rating")
    func testInitialReview() {
        let initialCardState = FSRSState()

        let againState = scheduler.review(currentState: initialCardState, rating: .again)
        #expect(againState.stability < 1.0)
        #expect(againState.repetitions == 1)
        #expect(againState.lapses == 1)
        #expect(againState.state == .learning)

        let hardState = scheduler.review(currentState: initialCardState, rating: .hard)
        #expect(hardState.stability > againState.stability)

        let goodState = scheduler.review(currentState: initialCardState, rating: .good)
        #expect(goodState.stability > hardState.stability)

        let easyState = scheduler.review(currentState: initialCardState, rating: .easy)
        #expect(easyState.stability > goodState.stability)
        #expect(easyState.state == .review)
    }

    @Test("Subsequent Review Increases Stability on Good Rating")
    func testSubsequentGoodReview() {
        let cardState = FSRSState(
            stability: 3.0,
            difficulty: 5.0,
            repetitions: 2,
            lapses: 0,
            state: .review,
            lastReviewDate: Date().addingTimeInterval(-86400 * 3),
            nextReviewDate: Date()
        )

        let nextState = scheduler.review(currentState: cardState, rating: .good)
        #expect(nextState.stability > cardState.stability)
        #expect(nextState.repetitions == 3)
        #expect(nextState.lapses == 0)
        #expect(nextState.state == .review)
    }

    @Test("Lapse on Again Rating Decreases Stability and Increments Lapses")
    func testLapseOnAgainRating() {
        let cardState = FSRSState(
            stability: 10.0,
            difficulty: 4.0,
            repetitions: 5,
            lapses: 0,
            state: .review,
            lastReviewDate: Date().addingTimeInterval(-86400 * 10),
            nextReviewDate: Date()
        )

        let lapsedState = scheduler.review(currentState: cardState, rating: .again)
        #expect(lapsedState.stability < cardState.stability)
        #expect(lapsedState.lapses == 1)
        #expect(lapsedState.state == .relearning)
    }

    @Test("Interval Formatting Displays Human-Friendly Labels")
    func testIntervalFormatting() {
        #expect(scheduler.formatInterval(seconds: 300) == "< 5m")
        #expect(scheduler.formatInterval(seconds: 43200) == "12h")
        #expect(scheduler.formatInterval(seconds: 86400) == "1d")
        #expect(scheduler.formatInterval(seconds: 86400 * 4) == "4d")
        #expect(scheduler.formatInterval(seconds: 86400 * 45) == "1.5mo")
        #expect(scheduler.formatInterval(seconds: 86400 * 365 * 2) == "2.0y")
    }
}
