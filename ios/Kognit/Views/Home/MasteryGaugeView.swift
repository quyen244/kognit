import SwiftUI

public struct MasteryGaugeView: View {
    public let masteryPercentage: Int
    public let projectedScore: String
    public let cellEnergyPercentage: Int
    public let geneticsPercentage: Int

    public init(
        masteryPercentage: Int = 78,
        projectedScore: String = "4.4 / 5.0",
        cellEnergyPercentage: Int = 85,
        geneticsPercentage: Int = 72
    ) {
        self.masteryPercentage = masteryPercentage
        self.projectedScore = projectedScore
        self.cellEnergyPercentage = cellEnergyPercentage
        self.geneticsPercentage = geneticsPercentage
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("AP Bio Mastery")
                        .font(.system(size: 13, weight: .bold))
                    
                    KognitBadge("On Track", icon: "checkmark.circle.fill", color: .green)
                }

                HStack(spacing: 4) {
                    Text("Projected Score:")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Text(projectedScore)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.green)
                }

                HStack(spacing: 10) {
                    Text("Cell Energy: \(cellEnergyPercentage)%")
                    Text("Genetics: \(geneticsPercentage)%")
                }
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            }

            Spacer()

            // Circular Radial Progress
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.08), lineWidth: 5)
                    .frame(width: 52, height: 52)

                Circle()
                    .trim(from: 0.0, to: CGFloat(masteryPercentage) / 100.0)
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 52, height: 52)
                    .animation(.spring(response: 0.8, dampingFraction: 0.7), value: masteryPercentage)

                Text("\(masteryPercentage)%")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
        .padding(14)
        .kognitCard()
    }
}
