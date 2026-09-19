import SwiftUI

public struct MCQQuestionView: View {
    public let question: ExamQuestionEntity
    public let onSelectOption: (OptionEntity) -> Void

    public init(question: ExamQuestionEntity, onSelectOption: @escaping (OptionEntity) -> Void) {
        self.question = question
        self.onSelectOption = onSelectOption
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("QUESTION \(question.questionIndex + 1)")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.blue)
                Spacer()
                if let tag = question.stimulusTag {
                    KognitBadge(tag, color: .purple, isOutline: true)
                }
            }

            // Stimulus Text (if present)
            if let stimulus = question.stimulusText {
                Text(stimulus)
                    .font(.system(size: 11, design: .serif))
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.primary.opacity(0.04)))
            }

            // Prompt
            Text(question.prompt)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineSpacing(2)

            // Multiple Choice Options (min 48pt touch target with bouncy button)
            VStack(spacing: 8) {
                ForEach(question.options.sorted { $0.letter < $1.letter }) { option in
                    let isSelected = question.selectedOptionId == option.id
                    let showResult = question.isAnswered && isSelected

                    Button(action: {
                        onSelectOption(option)
                    }) {
                        HStack(alignment: .center, spacing: 10) {
                            Text("\(option.letter). \(option.text)")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(textColor(for: option, isSelected: isSelected))
                                .multilineTextAlignment(.leading)

                            Spacer()

                            // Status Icon
                            if showResult {
                                Image(systemName: option.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(option.isCorrect ? .green : .red)
                            } else {
                                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                                    .font(.system(size: 12))
                                    .foregroundColor(isSelected ? .blue : .secondary.opacity(0.4))
                            }
                        }
                        .padding(12)
                        .frame(minHeight: 48) // 48pt touch target
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(backgroundColor(for: option, isSelected: isSelected))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(borderColor(for: option, isSelected: isSelected), lineWidth: 1.5)
                        )
                    }
                    .bouncyButton()
                }
            }

            // Distractor Rationale Feedback Callout
            if question.isAnswered, let selectedId = question.selectedOptionId,
               let selectedOption = question.options.first(where: { $0.id == selectedId }) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: selectedOption.isCorrect ? "sparkles" : "exclamationmark.triangle.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(selectedOption.isCorrect ? .green : .orange)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(selectedOption.isCorrect ? GenZMicroCopy.randomCorrect() : "Trap detected! 🎯 Not quite.")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(selectedOption.isCorrect ? .green : .orange)

                        Text(selectedOption.distractorRationale)
                            .font(.system(size: 10))
                            .foregroundColor(.primary.opacity(0.9))
                            .lineSpacing(2)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedOption.isCorrect ? Color.green.opacity(0.12) : Color.orange.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedOption.isCorrect ? Color.green.opacity(0.4) : Color.orange.opacity(0.4), lineWidth: 1.5)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .padding(14)
        .kognitCard(cornerRadius: 18)
    }

    private func backgroundColor(for option: OptionEntity, isSelected: Bool) -> Color {
        guard question.isAnswered && isSelected else {
            return Color(UIColor.systemBackground)
        }
        return option.isCorrect ? Color.green.opacity(0.14) : Color.red.opacity(0.14)
    }

    private func borderColor(for option: OptionEntity, isSelected: Bool) -> Color {
        guard question.isAnswered && isSelected else {
            return isSelected ? Color.blue : Color.primary.opacity(0.08)
        }
        return option.isCorrect ? Color.green : Color.red
    }

    private func textColor(for option: OptionEntity, isSelected: Bool) -> Color {
        guard question.isAnswered && isSelected else {
            return .primary
        }
        return option.isCorrect ? .green : .red
    }
}
