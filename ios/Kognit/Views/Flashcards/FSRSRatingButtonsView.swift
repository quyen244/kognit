import SwiftUI

public struct FSRSRatingButtonsView: View {
    public let card: FlashcardEntity?
    public let onRate: (FSRSRating) -> Void

    public init(card: FlashcardEntity?, onRate: @escaping (FSRSRating) -> Void) {
        self.card = card
        self.onRate = onRate
    }

    public var body: some View {
        VStack(spacing: 8) {
            // 4 Large Tap Target FSRS Rating Buttons (min 48pt touch target)
            HStack(spacing: 8) {
                // Again
                RatingOptionButton(
                    title: "Again",
                    interval: intervalLabel(for: .again),
                    icon: "arrow.counterclockwise",
                    color: .red
                ) {
                    HapticsService.shared.rigid()
                    onRate(.again)
                }

                // Hard
                RatingOptionButton(
                    title: "Hard",
                    interval: intervalLabel(for: .hard),
                    icon: "flame",
                    color: .orange
                ) {
                    HapticsService.shared.medium()
                    onRate(.hard)
                }

                // Good
                RatingOptionButton(
                    title: "Good",
                    interval: intervalLabel(for: .good),
                    icon: "checkmark",
                    color: .green
                ) {
                    HapticsService.shared.medium()
                    onRate(.good)
                }

                // Easy
                RatingOptionButton(
                    title: "Easy",
                    interval: intervalLabel(for: .easy),
                    icon: "bolt.fill",
                    color: .blue
                ) {
                    HapticsService.shared.rigid()
                    onRate(.easy)
                }
            }

            // FSRS Metadata Metrics Footer
            if let card = card {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        Text("FSRS Stability:")
                            .foregroundColor(.secondary)
                        Text("S=\(String(format: "%.1f", card.stability))d")
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Next:")
                            .foregroundColor(.secondary)
                        Text("+1 day")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                .font(.system(size: 9, design: .monospaced))
                .padding(.horizontal, 4)
            }
        }
    }

    private func intervalLabel(for rating: FSRSRating) -> String {
        guard let card = card else { return rating.defaultIntervalLabel }
        let snapshot = card.snapshotFSRSState()
        return FSRSScheduler.shared.intervalPreview(for: rating, currentState: snapshot)
    }
}

// MARK: - Rating Option Button (Large 48pt touch target with bounce)
private struct RatingOptionButton: View {
    let title: String
    let interval: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: icon)
                        .font(.system(size: 9, weight: .bold))
                    Text(title)
                        .font(.system(size: 11.5, weight: .black, design: .rounded))
                }
                Text(interval)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .opacity(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48) // 48pt touch target compliance
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.4), lineWidth: 1.5)
            )
            .foregroundColor(color)
        }
        .bouncyButton()
    }
}
