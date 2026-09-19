import SwiftUI

public struct Flashcard3DCardView: View {
    public let card: FlashcardEntity
    public let isFlipped: Bool
    public let onFlip: () -> Void
    public let onSwipeRate: (FSRSRating) -> Void

    @State private var dragOffset: CGSize = .zero
    @State private var isDragging: Bool = false

    public init(
        card: FlashcardEntity,
        isFlipped: Bool,
        onFlip: @escaping () -> Void,
        onSwipeRate: @escaping (FSRSRating) -> Void = { _ in }
    ) {
        self.card = card
        self.isFlipped = isFlipped
        self.onFlip = onFlip
        self.onSwipeRate = onSwipeRate
    }

    public var body: some View {
        ZStack {
            // Front & Back 3D Card
            ZStack {
                CardFrontView(card: card)
                    .opacity(isFlipped ? 0 : 1)
                    .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))

                CardBackView(card: card)
                    .opacity(isFlipped ? 1 : 0)
                    .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0))
            }

            // Swipe Threshold Indicator Overlays
            if dragOffset.width < -30 {
                // Swiping Left -> Again
                VStack {
                    HStack {
                        Spacer()
                        SwipeIndicatorBadge(text: "AGAIN", icon: "arrow.counterclockwise", color: .red)
                            .opacity(min(1.0, Double(-dragOffset.width / 80.0)))
                            .scaleEffect(min(1.15, max(0.8, Double(-dragOffset.width / 80.0))))
                    }
                    Spacer()
                }
                .padding(16)
            } else if dragOffset.width > 30 {
                // Swiping Right -> Good
                VStack {
                    HStack {
                        SwipeIndicatorBadge(text: "GOOD", icon: "checkmark", color: .green)
                            .opacity(min(1.0, Double(dragOffset.width / 80.0)))
                            .scaleEffect(min(1.15, max(0.8, Double(dragOffset.width / 80.0))))
                        Spacer()
                    }
                    Spacer()
                }
                .padding(16)
            } else if dragOffset.height < -40 {
                // Swiping Up -> Easy
                VStack {
                    SwipeIndicatorBadge(text: "EASY ⚡", icon: "bolt.fill", color: .blue)
                        .opacity(min(1.0, Double(-dragOffset.height / 90.0)))
                        .scaleEffect(min(1.15, max(0.8, Double(-dragOffset.height / 90.0))))
                    Spacer()
                }
                .padding(16)
            }
        }
        .frame(height: 260)
        .offset(dragOffset)
        .rotationEffect(.degrees(Double(dragOffset.width / 18)))
        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: dragOffset)
        .gesture(
            DragGesture(minimumDistance: 10)
                .onChanged { gesture in
                    dragOffset = gesture.translation
                    isDragging = true
                }
                .onEnded { gesture in
                    let threshold: CGFloat = 100
                    let verticalThreshold: CGFloat = -110

                    if gesture.translation.width < -threshold {
                        // Swipe Left: Again
                        HapticsService.shared.rigid()
                        withAnimation(.easeOut(duration: 0.25)) {
                            dragOffset = CGSize(width: -500, height: gesture.translation.height)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            dragOffset = .zero
                            isDragging = false
                            onSwipeRate(.again)
                        }
                    } else if gesture.translation.width > threshold {
                        // Swipe Right: Good
                        HapticsService.shared.rigid()
                        withAnimation(.easeOut(duration: 0.25)) {
                            dragOffset = CGSize(width: 500, height: gesture.translation.height)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            dragOffset = .zero
                            isDragging = false
                            onSwipeRate(.good)
                        }
                    } else if gesture.translation.height < verticalThreshold {
                        // Swipe Up: Easy
                        HapticsService.shared.rigid()
                        withAnimation(.easeOut(duration: 0.25)) {
                            dragOffset = CGSize(width: gesture.translation.width, height: -600)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            dragOffset = .zero
                            isDragging = false
                            onSwipeRate(.easy)
                        }
                    } else {
                        // Snap back with spring
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.65)) {
                            dragOffset = .zero
                            isDragging = false
                        }
                    }
                }
        )
        .onTapGesture {
            guard !isDragging else { return }
            onFlip()
        }
    }
}

// MARK: - Swipe Indicator Badge
private struct SwipeIndicatorBadge: View {
    let text: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .black))
            Text(text)
                .font(.system(size: 12, weight: .black, design: .rounded))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Capsule().fill(color))
        .foregroundColor(.white)
        .shadow(color: color.opacity(0.5), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Card Front View
private struct CardFrontView: View {
    let card: FlashcardEntity

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("QUESTION #\(card.cardIndex)")
                    .font(.system(size: 9.5, weight: .black, design: .monospaced))
                    .foregroundColor(.blue)
                Spacer()
                KognitBadge(card.unitTag, color: .purple, isOutline: true)
            }
            .padding(.bottom, 12)

            Spacer()

            // Question Text
            Text(card.front)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 8)

            // Optional Hint
            if let hint = card.hint {
                Text(hint)
                    .font(.system(size: 9.5, design: .serif))
                    .italic()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
            }

            Spacer()

            // Flip Prompt with dynamic micro-copy
            HStack(spacing: 5) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 10, weight: .bold))
                Text("Tap to flip • Swipe 👈 Again / 👉 Good / 👆 Easy")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.purple.opacity(0.85))
            .padding(.top, 8)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color(UIColor.secondarySystemBackground), Color(UIColor.tertiarySystemBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.purple.opacity(0.12), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Card Back View
private struct CardBackView: View {
    let card: FlashcardEntity

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                    Text("ANSWER & EXPLANATION")
                        .font(.system(size: 9.5, weight: .black, design: .rounded))
                        .foregroundColor(.green)
                }
                Spacer()
                KognitBadge("FSRS-4.5 ⚡", color: .green)
            }
            .padding(.bottom, 10)

            Spacer()

            // Correct Answer
            Text(card.back)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundColor(.green)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 6)

            // Explanation
            if !card.explanation.isEmpty {
                Text(card.explanation)
                    .font(.system(size: 10))
                    .foregroundColor(.primary.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                    .padding(.top, 8)
                    .padding(.horizontal, 4)
            }

            Spacer()

            Text("Rate difficulty below or swipe card:")
                .font(.system(size: 8.5, weight: .medium))
                .foregroundColor(.secondary)
                .padding(.top, 6)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.09), Color(UIColor.secondarySystemBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.green.opacity(0.4), lineWidth: 1.5)
        )
        .shadow(color: Color.green.opacity(0.12), radius: 12, x: 0, y: 6)
    }
}
