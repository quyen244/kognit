import SwiftUI

// MARK: - Achievement Badge Definition
public struct AchievementBadge: Identifiable, Sendable {
    public let id: String
    public let title: String
    public let icon: String
    public let description: String
    public let isUnlocked: Bool
    public let colorHexes: [String]

    public init(
        id: String,
        title: String,
        icon: String,
        description: String,
        isUnlocked: Bool = false,
        colorHexes: [String] = ["#3B82F6", "#8B5CF6"]
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.description = description
        self.isUnlocked = isUnlocked
        self.colorHexes = colorHexes
    }
}

// MARK: - Level & XP System
public struct LevelSystem: Sendable {
    public static func calculateLevel(from xp: Int) -> (level: Int, title: String, currentXP: Int, nextLevelXP: Int, progress: Double) {
        let xpPerLevel = 500
        let level = max(1, (xp / xpPerLevel) + 1)
        let currentLevelBaseXP = (level - 1) * xpPerLevel
        let currentXPInLevel = xp - currentLevelBaseXP
        let progress = min(1.0, max(0.0, Double(currentXPInLevel) / Double(xpPerLevel)))

        let title: String
        switch level {
        case 1: title = "Novice Scholar"
        case 2: title = "Study Grinder"
        case 3: title = "AP Apprentice"
        case 4: title = "FSRS Master"
        case 5: title = "Bio Beast"
        case 6: title = "Memory Wizard"
        case 7: title = "Level 7 Scholar"
        case 8: title = "Olympiad Candidate"
        default: title = "Grandmaster Polymath"
        }

        return (level, title, currentXPInLevel, xpPerLevel, progress)
    }

    public static let sampleBadges: [AchievementBadge] = [
        AchievementBadge(id: "streak_12", title: "Cooking 🔥", icon: "flame.fill", description: "Maintained a 12-day study streak", isUnlocked: true, colorHexes: ["#EF4444", "#F59E0B"]),
        AchievementBadge(id: "fsrs_master", title: "FSRS Beast ⚡", icon: "bolt.fill", description: "Reviewed 50+ cards with FSRS-4.5", isUnlocked: true, colorHexes: ["#8B5CF6", "#EC4899"]),
        AchievementBadge(id: "bio_genius", title: "Bio Beast 🧬", icon: "leaf.fill", description: "Scored 4.4+ on AP Biology diagnostic", isUnlocked: true, colorHexes: ["#10B981", "#3B82F6"]),
        AchievementBadge(id: "night_owl", title: "Night Owl 🦉", icon: "moon.stars.fill", description: "Completed study session after 9 PM", isUnlocked: true, colorHexes: ["#6366F1", "#A855F7"]),
        AchievementBadge(id: "perfect_frq", title: "FRQ Slayer 📝", icon: "star.fill", description: "Achieved 4/4 points on an AP Rubric", isUnlocked: false, colorHexes: ["#F59E0B", "#EF4444"]),
        AchievementBadge(id: "perfect_5", title: "Target 5.0 🏆", icon: "trophy.fill", description: "Reach 90%+ diagnostic mastery", isUnlocked: false, colorHexes: ["#EAB308", "#F97316"])
    ]
}

// MARK: - Encouraging Gen-Z Micro-Copy
public struct GenZMicroCopy: Sendable {
    public static func randomCorrect() -> String {
        [
            "No cap, you cooked this! 🧠",
            "W recall! Big brain energy!",
            "It's giving 5 on the AP! ✨",
            "You ate that concept up!",
            "Locked in! Retention through the roof 🚀",
            "Sheeesh, pure memory mastery! 🔥"
        ].randomElement() ?? "Great job! 🔥"
    }

    public static func randomIncorrect() -> String {
        [
            "Minor setback, major comeback! 💪",
            "Lock back in, you got this next round!",
            "FSRS got your back — we'll review this soon!",
            "Not quite, but we're learning the traps! 🎯",
            "Shake it off, big brains learn from mistakes!"
        ].randomElement() ?? "Keep pushing!"
    }

    public static func randomDeckComplete() -> String {
        [
            "Deck conquered! Absolute masterclass! 🏆",
            "You ate that deck and left no crumbs! 🥞",
            "FSRS retention locked in! Leveling up! ⚡",
            "AP exam doesn't stand a chance against you! 💯"
        ].randomElement() ?? "Deck complete!"
    }
}
