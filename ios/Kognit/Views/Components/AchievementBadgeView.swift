import SwiftUI

public struct AchievementBadgeView: View {
    public let badges: [AchievementBadge]

    public init(badges: [AchievementBadge] = LevelSystem.sampleBadges) {
        self.badges = badges
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("ACHIEVEMENTS & TROPHIES")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(badges.filter { $0.isUnlocked }.count)/\(badges.count) Unlocked")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.purple)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(badges) { badge in
                        BadgePill(badge: badge)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct BadgePill: View {
    let badge: AchievementBadge

    var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(
                        badge.isUnlocked
                        ? LinearGradient(colors: colorsFromHexes(badge.colorHexes), startPoint: .topLeading, endPoint: .bottomTrailing)
                        : LinearGradient(colors: [.gray.opacity(0.3), .gray.opacity(0.4)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 22, height: 22)

                Image(systemName: badge.icon)
                    .font(.system(size: 9))
                    .foregroundColor(badge.isUnlocked ? .white : .secondary)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(badge.title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(badge.isUnlocked ? .primary : .secondary)
                Text(badge.isUnlocked ? "Unlocked" : "Locked")
                    .font(.system(size: 7.5, weight: .semibold))
                    .foregroundColor(badge.isUnlocked ? .green : .secondary.opacity(0.6))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(badge.isUnlocked ? Color(UIColor.secondarySystemBackground) : Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(badge.isUnlocked ? Color.purple.opacity(0.3) : Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func colorsFromHexes(_ hexes: [String]) -> [Color] {
        hexes.map { hex in
            let clean = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            var int: UInt64 = 0
            Scanner(string: clean).scanHexInt64(&int)
            let r = (int >> 16) & 0xFF
            let g = (int >> 8) & 0xFF
            let b = int & 0xFF
            return Color(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
        }
    }
}
