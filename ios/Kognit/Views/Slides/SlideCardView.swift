import SwiftUI

public struct SlideCardView: View {
    public let slide: SlideEntity
    @Binding var selectedTerm: FormulaTermEntity?

    public init(slide: SlideEntity, selectedTerm: Binding<FormulaTermEntity?>) {
        self.slide = slide
        self._selectedTerm = selectedTerm
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Top Bar: Badge & Tag
            HStack {
                KognitBadge(slide.slideType.rawValue, color: badgeColor(for: slide.slideType))
                Spacer()
                Text("ID: \(slide.slideIdTag)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            // Title
            Text(slide.title)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundColor(badgeColor(for: slide.slideType))
                .lineLimit(2)

            // Summary
            Text(slide.summary)
                .font(.system(size: 12))
                .foregroundColor(.primary.opacity(0.9))
                .lineSpacing(2.5)

            // Content Body by Slide Type
            switch slide.slideType {
            case .keyConcept:
                keyConceptContent
            case .formulaHighlight:
                formulaHighlightContent
            case .digestibleSummary:
                digestibleSummaryContent
            }

            // AP Exam Trap Callout (if present)
            if let trap = slide.apExamTrap {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("No cap: AP Exam Trap! ⚠️")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(.orange)
                        Text(trap)
                            .font(.system(size: 9.5))
                            .foregroundColor(.primary.opacity(0.9))
                            .lineSpacing(1.5)
                    }
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.35), lineWidth: 1.5)
                )
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .kognitCard(cornerRadius: 20)
    }

    // MARK: - Key Concept Layout
    private var keyConceptContent: some View {
        VStack(spacing: 8) {
            ForEach(slide.bulletPoints, id: \.self) { point in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: point.contains("Investment") ? "bolt.fill" : "dollarsign.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(point.contains("Investment") ? .orange : .green)
                        .padding(.top, 2)

                    Text(point)
                        .font(.system(size: 10.5))
                        .foregroundColor(.primary.opacity(0.9))
                        .lineSpacing(1.5)
                }
                .padding(9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.systemBackground)))
            }
        }
    }

    // MARK: - Formula Highlight Layout
    private var formulaHighlightContent: some View {
        FormulaHighlightView(
            equation: slide.equationString ?? "C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O + 30-32 ATP",
            terms: slide.formulaTerms,
            selectedTerm: $selectedTerm
        )
    }

    // MARK: - Digestible Summary Layout (OIL RIG mnemonic)
    private var digestibleSummaryContent: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                // OIL
                VStack(spacing: 3) {
                    Text("OIL")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.red)
                    Text("Oxidation Is Loss")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                    Text("Loss of e⁻ or H")
                        .font(.system(size: 8.5))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.red.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.35), lineWidth: 1.5))

                // RIG
                VStack(spacing: 3) {
                    Text("RIG")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.green)
                    Text("Reduction Is Gain")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                    Text("Gain of e⁻ or H")
                        .font(.system(size: 8.5))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.green.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.green.opacity(0.35), lineWidth: 1.5))
            }

            Text("In respiration: Glucose is **oxidized** to CO₂, while oxygen is **reduced** to water. Keep this straight for test day! 🎯")
                .font(.system(size: 10))
                .foregroundColor(.primary.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 2)
        }
    }

    private func badgeColor(for type: SlideType) -> Color {
        switch type {
        case .keyConcept: return .blue
        case .formulaHighlight: return .purple
        case .digestibleSummary: return .green
        }
    }
}
