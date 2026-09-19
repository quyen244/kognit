import SwiftUI

// MARK: - Kognit Card Background Modifier
public struct KognitCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var borderColor: Color = Color.primary.opacity(0.1)

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(UIColor.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
    }
}

public extension View {
    func kognitCard(cornerRadius: CGFloat = 16, borderColor: Color = Color.primary.opacity(0.1)) -> some View {
        modifier(KognitCardModifier(cornerRadius: cornerRadius, borderColor: borderColor))
    }
}

// MARK: - Badge View
public struct KognitBadge: View {
    public let text: String
    public var icon: String? = nil
    public var color: Color = .blue
    public var isOutline: Bool = false

    public init(_ text: String, icon: String? = nil, color: Color = .blue, isOutline: Bool = false) {
        self.text = text
        self.icon = icon
        self.color = color
        self.isOutline = isOutline
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(text)
                .font(.system(size: 10, weight: .bold))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(isOutline ? Color.clear : color.opacity(0.15))
        )
        .overlay(
            Capsule()
                .stroke(color.opacity(isOutline ? 0.6 : 0.2), lineWidth: 1)
        )
        .foregroundColor(color)
    }
}

// MARK: - Streak Badge
public struct StreakBadge: View {
    public let streakDays: Int

    public init(streakDays: Int = 12) {
        self.streakDays = streakDays
    }

    public var body: some View {
        HStack(spacing: 4) {
            Text("🔥")
                .font(.system(size: 10))
            Text("\(streakDays)-Day Streak")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.red.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}
