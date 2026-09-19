import SwiftUI

public struct ConfettiParticle: Identifiable {
    public let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var rotation: Double
    var xVelocity: CGFloat
    var yVelocity: CGFloat
    var rotationVelocity: Double
    var opacity: Double = 1.0
}

public struct ConfettiView: View {
    @Binding var isActive: Bool
    @State private var particles: [ConfettiParticle] = []
    @State private var timer: Timer? = nil

    public init(isActive: Binding<Bool>) {
        self._isActive = isActive
    }

    private let colors: [Color] = [
        .blue, .purple, .pink, .yellow, .green, .orange, .cyan, .mint
    ]

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { p in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(p.color)
                        .frame(width: p.size, height: p.size * 1.5)
                        .rotationEffect(.degrees(p.rotation))
                        .position(x: p.x, y: p.y)
                        .opacity(p.opacity)
                }
            }
            .allowsHitTesting(false)
            .onChange(of: isActive) { _, active in
                if active {
                    spawnParticles(in: geo.size)
                }
            }
        }
    }

    private func spawnParticles(in size: CGSize) {
        var newParticles: [ConfettiParticle] = []
        for _ in 0..<50 {
            let startX = size.width / 2.0 + CGFloat.random(in: -40...40)
            let startY = size.height * 0.4 + CGFloat.random(in: -30...30)
            let p = ConfettiParticle(
                x: startX,
                y: startY,
                size: CGFloat.random(in: 6...12),
                color: colors.randomElement() ?? .yellow,
                rotation: Double.random(in: 0...360),
                xVelocity: CGFloat.random(in: -250...250),
                yVelocity: CGFloat.random(in: -450 ... -150),
                rotationVelocity: Double.random(in: -360...360)
            )
            newParticles.append(p)
        }
        self.particles = newParticles
        HapticsService.shared.success()

        // Run animation tick
        let startTime = Date()
        let duration: Double = 2.5

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { t in
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= duration {
                t.invalidate()
                self.particles.removeAll()
                self.isActive = false
            } else {
                let dt: CGFloat = 1.0 / 60.0
                let gravity: CGFloat = 580.0

                for i in 0..<self.particles.count {
                    self.particles[i].x += self.particles[i].xVelocity * dt
                    self.particles[i].y += self.particles[i].yVelocity * dt
                    self.particles[i].yVelocity += gravity * dt
                    self.particles[i].rotation += self.particles[i].rotationVelocity * Double(dt)
                    if elapsed > 1.5 {
                        self.particles[i].opacity = max(0, 1.0 - (elapsed - 1.5) / 1.0)
                    }
                }
            }
        }
    }
}
