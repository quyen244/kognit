import Foundation

// MARK: - FSRS-4.5 Scheduler Implementation
public final class FSRSScheduler: Sendable {
    public static let shared = FSRSScheduler()

    // Default 17 FSRS-4.5 parameters
    public struct Parameters: Sendable {
        public var w: [Double]
        public var requestRetention: Double
        public var maximumInterval: Double // In days

        public init(
            w: [Double] = [
                0.40255, 1.18385, 3.173, 15.69105, // w0-w3: Initial stability for ratings 1-4
                7.1949, 0.5345,                     // w4-w5: Initial difficulty
                1.4604, 0.0046,                     // w6-w7: Difficulty update
                1.54575, 0.1192, 1.01925,           // w8-w10: Stability on recall
                1.9395, 0.11, 0.29605, 0.22695,     // w11-w14: Stability on forget
                0.56975, 2.85535                    // w15-w16: Hard penalty & Easy bonus
            ],
            requestRetention: Double = 0.90,
            maximumInterval: Double = 36500.0 // 100 years cap
        ) {
            self.w = w
            self.requestRetention = requestRetention
            self.maximumInterval = maximumInterval
        }
    }

    public let parameters: Parameters
    private let factor: Double = 19.0 / 81.0
    private let decay: Double = -0.5

    public init(parameters: Parameters = Parameters()) {
        self.parameters = parameters
    }

    // MARK: - Retrievability Formula R(t, S)
    public func retrievability(elapsedDays: Double, stability: Double) -> Double {
        guard stability > 0 else { return 0.0 }
        return pow(1.0 + factor * (elapsedDays / stability), decay)
    }

    // MARK: - Calculate Next State from Rating
    public func review(
        currentState: FSRSState,
        rating: FSRSRating,
        reviewDate: Date = Date()
    ) -> FSRSState {
        let elapsedDays: Double
        if let lastDate = currentState.lastReviewDate {
            elapsedDays = max(0.0, reviewDate.timeIntervalSince(lastDate) / 86400.0)
        } else {
            elapsedDays = 0.0
        }

        let isFirstReview = currentState.state == .new

        let newDifficulty: Double
        let newStability: Double
        let newCardState: CardRepetitionState
        var newRepetitions = currentState.repetitions
        var newLapses = currentState.lapses

        let g = Double(rating.rawValue)

        if isFirstReview {
            // Initial Review
            newStability = initStability(rating: rating)
            newDifficulty = initDifficulty(rating: rating)
            newRepetitions = 1

            switch rating {
            case .again:
                newCardState = .learning
                newLapses += 1
            case .hard, .good:
                newCardState = .learning
            case .easy:
                newCardState = .review
            }
        } else {
            // Subsequent Review
            let r = retrievability(elapsedDays: elapsedDays, stability: currentState.stability)
            newDifficulty = nextDifficulty(currentD: currentState.difficulty, rating: rating)

            if rating == .again {
                newStability = nextForgetStability(
                    currentD: newDifficulty,
                    currentS: currentState.stability,
                    retrievability: r
                )
                newLapses += 1
                newCardState = .relearning
            } else {
                newStability = nextRecallStability(
                    currentD: newDifficulty,
                    currentS: currentState.stability,
                    retrievability: r,
                    rating: rating
                )
                newRepetitions += 1
                newCardState = .review
            }
        }

        let clampedStability = min(max(0.1, newStability), parameters.maximumInterval)
        let intervalDays = calculateInterval(stability: clampedStability)

        let nextReviewSeconds: TimeInterval
        switch rating {
        case .again:
            nextReviewSeconds = 10 * 60 // 10 minutes
        case .hard:
            nextReviewSeconds = 12 * 3600 // 12 hours
        case .good:
            nextReviewSeconds = max(86400, intervalDays * 86400) // At least 1 day
        case .easy:
            nextReviewSeconds = max(4 * 86400, intervalDays * 86400 * 1.3) // At least 4 days
        }

        let nextDate = reviewDate.addingTimeInterval(nextReviewSeconds)

        return FSRSState(
            stability: clampedStability,
            difficulty: newDifficulty,
            repetitions: newRepetitions,
            lapses: newLapses,
            state: newCardState,
            lastReviewDate: reviewDate,
            nextReviewDate: nextDate
        )
    }

    // MARK: - Interval Label Preview (e.g., "< 10m", "12h", "1d", "4d")
    public func intervalPreview(for rating: FSRSRating, currentState: FSRSState) -> String {
        let previewState = review(currentState: currentState, rating: rating)
        let intervalSeconds = previewState.nextReviewDate.timeIntervalSince(Date())
        return formatInterval(seconds: intervalSeconds)
    }

    public func formatInterval(seconds: TimeInterval) -> String {
        if seconds < 3600 {
            let minutes = max(1, Int(seconds / 60))
            return "< \(minutes)m"
        } else if seconds < 86400 {
            let hours = Int(round(seconds / 3600.0))
            return "\(hours)h"
        } else if seconds < 30 * 86400 {
            let days = Int(round(seconds / 86400.0))
            return "\(days)d"
        } else if seconds < 365 * 86400 {
            let months = Double(seconds) / (30.0 * 86400.0)
            return String(format: "%.1fmo", months)
        } else {
            let years = Double(seconds) / (365.0 * 86400.0)
            return String(format: "%.1fy", years)
        }
    }

    // MARK: - Private Math Equations
    private func initStability(rating: FSRSRating) -> Double {
        let index = rating.rawValue - 1
        guard index >= 0 && index < 4 else { return parameters.w[0] }
        return max(0.1, parameters.w[index])
    }

    private func initDifficulty(rating: FSRSRating) -> Double {
        let g = Double(rating.rawValue)
        let d0 = parameters.w[4] - parameters.w[5] * (g - 3.0)
        return min(max(d0, 1.0), 10.0)
    }

    private func nextDifficulty(currentD: Double, rating: FSRSRating) -> Double {
        let g = Double(rating.rawValue)
        let deltaD = -parameters.w[6] * (g - 3.0)
        let meanReversion = parameters.w[7] * initDifficulty(rating: .good) + (1.0 - parameters.w[7]) * (currentD + deltaD)
        return min(max(meanReversion, 1.0), 10.0)
    }

    private func nextRecallStability(
        currentD: Double,
        currentS: Double,
        retrievability: Double,
        rating: FSRSRating
    ) -> Double {
        let hardPenalty = (rating == .hard) ? parameters.w[15] : 1.0
        let easyBonus = (rating == .easy) ? parameters.w[16] : 1.0

        let factor1 = exp(parameters.w[8])
        let factor2 = 11.0 - currentD
        let factor3 = pow(currentS, -parameters.w[9])
        let factor4 = exp((1.0 - retrievability) * parameters.w[10]) - 1.0

        let sPrime = currentS * (1.0 + factor1 * factor2 * factor3 * factor4 * hardPenalty * easyBonus)
        return max(0.1, sPrime)
    }

    private func nextForgetStability(
        currentD: Double,
        currentS: Double,
        retrievability: Double
    ) -> Double {
        let factor1 = parameters.w[11]
        let factor2 = pow(currentD, -parameters.w[12])
        let factor3 = pow(currentS + 1.0, parameters.w[13]) - 1.0
        let factor4 = exp((1.0 - retrievability) * parameters.w[14])

        let sPrime = factor1 * factor2 * factor3 * factor4
        return max(0.1, min(sPrime, currentS))
    }

    private func calculateInterval(stability: Double) -> Double {
        let interval = (stability / factor) * (pow(parameters.requestRetention, 1.0 / decay) - 1.0)
        return min(max(1.0, round(interval)), parameters.maximumInterval)
    }
}
