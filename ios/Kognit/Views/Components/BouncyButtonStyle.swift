import SwiftUI

public struct BouncyButtonStyle: ButtonStyle {
    public var scaleAmount: CGFloat = 0.94
    public var triggerHaptic: Bool = true

    public init(scaleAmount: CGFloat = 0.94, triggerHaptic: Bool = true) {
        self.scaleAmount = scaleAmount
        self.triggerHaptic = triggerHaptic
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scaleAmount : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, isPressed in
                if isPressed && triggerHaptic {
                    HapticsService.shared.light()
                }
            }
    }
}

public extension View {
    func bouncyButton(scaleAmount: CGFloat = 0.94) -> some View {
        buttonStyle(BouncyButtonStyle(scaleAmount: scaleAmount))
    }
}
