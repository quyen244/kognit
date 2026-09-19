import SwiftUI

public struct ExamResultsView: View {
    public let result: ExamResultEntity
    public let standard: ExamStandard
    public let onRestart: () -> Void

    @State private var showConfetti: Bool = true

    public init(result: ExamResultEntity, standard: ExamStandard = .ap, onRestart: @escaping () -> Void) {
        self.result = result
        self.standard = standard
        self.onRestart = onRestart
    }

    public var body: some View {
        ZStack {
            VStack(spacing: 16) {
                Spacer()

                // Trophy / Medal Badge with Neon Glow
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.orange.opacity(0.25), .yellow.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange.opacity(0.6), radius: 12)
                }

                VStack(spacing: 5) {
                    Text("Diagnostic Exam Complete! 🚀")
                        .font(.system(size: 20, weight: .black, design: .rounded))

                    Text(result.percentageScore >= 70 ? "No cap, you're literally built different! 🧠" : "Solid diagnostic run! Ready to lock in? 💪")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundColor(.purple)

                    Text("+250 XP Added to Scholar Level!")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(.orange)
                }

                // Score Card
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(standard.shortCode) Scaled Score")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(result.scaledScoreDisplay)
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.orange)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text("Accuracy")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                            Text("\(Int(result.percentageScore))%")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .foregroundColor(.green)
                        }
                    }

                    Divider()

                    HStack(spacing: 16) {
                        VStack(spacing: 2) {
                            Text("\(result.totalPointsEarned) / \(result.totalPointsPossible)")
                                .font(.system(size: 14, weight: .black, design: .rounded))
                            Text("Points")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()

                        VStack(spacing: 2) {
                            Text(formattedDuration(seconds: result.durationSeconds))
                                .font(.system(size: 14, weight: .black, design: .rounded))
                            Text("Duration")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)

                        Divider()

                        VStack(spacing: 2) {
                            Text(result.percentageScore >= 70 ? "5.0 Trajectory ✨" : "Need Review 📚")
                                .font(.system(size: 12, weight: .black, design: .rounded))
                                .foregroundColor(result.percentageScore >= 70 ? .green : .orange)
                            Text("Trajectory")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(16)
                .kognitCard(cornerRadius: 18)

                Button(action: onRestart) {
                    Label("Retake Diagnostic Exam", systemImage: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .bouncyButton()

                Spacer()
            }
            .padding(.horizontal, 16)

            ConfettiView(isActive: $showConfetti)
        }
        .onAppear {
            showConfetti = true
            HapticsService.shared.success()
        }
    }

    private func formattedDuration(seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return "\(mins)m \(secs)s"
    }
}
