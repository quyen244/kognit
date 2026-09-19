import SwiftUI

public struct FormulaHighlightView: View {
    public let equation: String
    public let terms: [FormulaTermEntity]
    @Binding var selectedTerm: FormulaTermEntity?

    public init(
        equation: String = "C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O + 30-32 ATP",
        terms: [FormulaTermEntity] = [],
        selectedTerm: Binding<FormulaTermEntity?>
    ) {
        self.equation = equation
        self.terms = terms
        self._selectedTerm = selectedTerm
    }

    public var body: some View {
        VStack(spacing: 10) {
            // Main Formula Box (LaTeX / Math style)
            VStack(spacing: 4) {
                Text(equation)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 8)

                Text("Tap a term below to inspect stoichiometry:")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.tertiarySystemBackground)))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )

            // Interactive Variable Pills Grid
            HStack(spacing: 6) {
                ForEach(terms) { term in
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            if selectedTerm?.id == term.id {
                                selectedTerm = nil
                            } else {
                                selectedTerm = term
                            }
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(term.symbol)
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(colorFromHex(term.colorHex))
                            Text(term.name)
                                .font(.system(size: 8))
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTerm?.id == term.id ? colorFromHex(term.colorHex).opacity(0.2) : Color(UIColor.systemBackground))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedTerm?.id == term.id ? colorFromHex(term.colorHex) : Color.primary.opacity(0.08), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Interactive Tip Detail Box
            if let term = selectedTerm {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(colorFromHex(term.colorHex))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(term.symbol) (\(term.name))")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(colorFromHex(term.colorHex))
                        Text(term.explanation)
                            .font(.system(size: 8.5))
                            .foregroundColor(.primary.opacity(0.9))
                    }
                    Spacer()
                }
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorFromHex(term.colorHex).opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(colorFromHex(term.colorHex).opacity(0.3), lineWidth: 1)
                )
                .transition(.scale(scale: 0.95).combined(with: .opacity))
            } else {
                Text("Tap a reactant or product above to inspect role in AP Biology.")
                    .font(.system(size: 8.5, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
            }
        }
    }

    private func colorFromHex(_ hex: String) -> Color {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleanHex.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (59, 130, 246)
        }
        return Color(red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255)
    }
}
