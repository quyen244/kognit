import SwiftUI

public struct ExamTimerView: View {
    public let remainingSeconds: Int
    public let isWarning: Bool

    public init(remainingSeconds: Int, isWarning: Bool = false) {
        self.remainingSeconds = remainingSeconds
        self.isWarning = isWarning
    }

    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: 10))
                .foregroundColor(isWarning ? .red : .orange)
                .symbolEffect(.pulse, isActive: isWarning)

            Text(formattedTime)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(isWarning ? .red : .orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(isWarning ? Color.red.opacity(0.12) : Color.orange.opacity(0.12))
        )
        .overlay(
            Capsule()
                .stroke(isWarning ? Color.red.opacity(0.3) : Color.orange.opacity(0.3), lineWidth: 1)
        )
    }

    private var formattedTime: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
