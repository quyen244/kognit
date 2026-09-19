import SwiftUI

public struct LevelProgressCard: View {
    public let xp: Int

    public init(xp: Int = 1850) {
        self.xp = xp
    }

    public var body: some View {
        let (level, title, currentXPInLevel, nextLevelXP, progress) = LevelSystem.calculateLevel(from: xp)

        VStack(spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        Text("\(level)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(title)
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                        Text("\(currentXPInLevel) / \(nextLevelXP) XP to Level \(level + 1)")
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 3) {
                    Text("⚡ 2x XP")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.orange.opacity(0.15)))
                .overlay(Capsule().stroke(Color.orange.opacity(0.3), lineWidth: 1))
            }

            // Animated XP Gradient Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.08))
                        .frame(height: 6)

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.blue, Color.purple, Color.pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * CGFloat(progress), height: 6)
                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 6)

            HStack {
                Text("🔥 Study streak active: bonus XP awarded per card!")
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.purple)
            }
        }
        .padding(14)
        .kognitCard(cornerRadius: 16)
    }
}
