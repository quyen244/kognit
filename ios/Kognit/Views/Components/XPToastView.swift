import SwiftUI

public struct XPToastView: View {
    public let xpAmount: Int
    public let message: String
    @Binding var isPresented: Bool

    public init(xpAmount: Int, message: String = "Recall Locked In! 🧠", isPresented: Binding<Bool>) {
        self.xpAmount = xpAmount
        self.message = message
        self._isPresented = isPresented
    }

    public var body: some View {
        if isPresented {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 24, height: 24)
                    Text("⚡")
                        .font(.system(size: 11))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("+\(xpAmount) XP")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text(message)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "#1E1B4B"), Color(hex: "#312E81")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .overlay(
                Capsule()
                    .stroke(
                        LinearGradient(
                            colors: [.purple.opacity(0.6), .pink.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(color: .purple.opacity(0.4), radius: 12, x: 0, y: 4)
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .scale(scale: 0.8)).combined(with: .opacity),
                removal: .scale(scale: 0.9).combined(with: .opacity)
            ))
            .onAppear {
                HapticsService.shared.medium()
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        isPresented = false
                    }
                }
            }
        }
    }
}

fileprivate extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
