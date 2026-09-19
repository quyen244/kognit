import SwiftUI
import SwiftData

public struct FlashcardDeckView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FlashcardEntity.cardIndex) private var allCards: [FlashcardEntity]
    @State private var viewModel = FlashcardDeckViewModel()

    @State private var showConfetti: Bool = false
    @State private var showXPToast: Bool = false
    @State private var earnedXP: Int = 35
    @State private var toastMessage: String = "Recall Locked In! 🧠"

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 14) {
                    if viewModel.cards.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            Text("No Flashcards Available")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text("Ingest a document to generate an active recall deck.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .frame(maxHeight: .infinity)
                    } else if viewModel.sessionComplete {
                        // Session Completed State
                        sessionCompletedView
                    } else {
                        // Active Review Session
                        VStack(spacing: 12) {
                            // Header Counter & Badges
                            HStack {
                                HStack(spacing: 6) {
                                    Text("AP Biology Deck")
                                        .font(.system(size: 14, weight: .black, design: .rounded))
                                    KognitBadge("+15 XP/card", color: .purple)
                                }
                                Spacer()
                                KognitBadge(viewModel.progressText, color: .primary)
                            }

                            // Deck Progress Bar
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.1))
                                        .frame(height: 6)

                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [.blue, .purple, .pink, .green],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geo.size.width * CGFloat(viewModel.progress), height: 6)
                                        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.progress)
                                }
                            }
                            .frame(height: 6)

                            // 3D Flippable Flashcard with Swipe Physics
                            if let card = viewModel.currentCard {
                                Flashcard3DCardView(
                                    card: card,
                                    isFlipped: viewModel.isFlipped,
                                    onFlip: {
                                        viewModel.flipCard()
                                    },
                                    onSwipeRate: { rating in
                                        handleCardRated(rating: rating)
                                    }
                                )

                                // FSRS Rating Buttons
                                FSRSRatingButtonsView(card: card) { rating in
                                    handleCardRated(rating: rating)
                                }
                                .padding(.top, 4)
                            }

                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)

                // Top Floating XP Toast
                VStack {
                    XPToastView(xpAmount: earnedXP, message: toastMessage, isPresented: $showXPToast)
                        .padding(.top, 10)
                        .padding(.horizontal, 24)
                    Spacer()
                }

                // Celebration Confetti
                ConfettiView(isActive: $showConfetti)
            }
            .navigationTitle("Active Recall")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if !allCards.isEmpty {
                    viewModel.setCards(allCards)
                }
            }
            .onChange(of: allCards) { _, newCards in
                if !newCards.isEmpty && viewModel.cards.isEmpty {
                    viewModel.setCards(newCards)
                }
            }
        }
    }

    private func handleCardRated(rating: FSRSRating) {
        viewModel.rateCard(rating, modelContext: modelContext)

        // Award XP & trigger micro-animation
        switch rating {
        case .again:
            earnedXP = 15
            toastMessage = "Learning in progress! 🔄"
        case .hard:
            earnedXP = 25
            toastMessage = "Good effort! Building stability 💪"
        case .good:
            earnedXP = 35
            toastMessage = GenZMicroCopy.randomCorrect()
        case .easy:
            earnedXP = 50
            toastMessage = "Masterclass! +50 XP ⚡"
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
            showXPToast = true
        }

        // Check if session completed
        if viewModel.sessionComplete {
            showConfetti = true
            HapticsService.shared.success()
        }
    }

    // MARK: - Session Completed View
    private var sessionCompletedView: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.green.opacity(0.2), Color.cyan.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 90, height: 90)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.yellow)
                    .shadow(color: .yellow.opacity(0.5), radius: 10)
            }

            VStack(spacing: 6) {
                Text("Deck Conquered! 🏆")
                    .font(.system(size: 22, weight: .black, design: .rounded))

                Text(GenZMicroCopy.randomDeckComplete())
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.purple)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text("+150 Bonus XP Earned!")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.orange)
            }

            // Stats Card
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(viewModel.cards.count)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.blue)
                    Text("Reviewed")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()

                VStack(spacing: 2) {
                    Text("92%")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.green)
                    Text("Target Retention")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)

                Divider()

                VStack(spacing: 2) {
                    Text("+1 Day")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.purple)
                    Text("Next Due")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(14)
            .kognitCard(cornerRadius: 18)

            Button(action: {
                viewModel.restartSession()
            }) {
                Label("Review Deck Again", systemImage: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .bouncyButton()
            .padding(.horizontal, 20)

            Spacer()
        }
        .onAppear {
            showConfetti = true
        }
    }
}
