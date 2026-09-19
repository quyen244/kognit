import SwiftUI

public struct FRQQuestionView: View {
    public let question: ExamQuestionEntity
    @Binding var studentInput: String
    public let isEvaluated: Bool
    public let onEvaluate: () -> Void

    public init(
        question: ExamQuestionEntity,
        studentInput: Binding<String>,
        isEvaluated: Bool,
        onEvaluate: @escaping () -> Void
    ) {
        self.question = question
        self._studentInput = studentInput
        self.isEvaluated = isEvaluated
        self.onEvaluate = onEvaluate
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text("FRQ QUESTION \(question.questionIndex + 1) (\(question.maxPoints) POINTS)")
                    .font(.system(size: 10, weight: .black, design: .monospaced))
                    .foregroundColor(.purple)
                Spacer()
                KognitBadge("Official AP Rubric 📝", color: .purple)
            }

            // Prompt
            Text(question.prompt)
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .lineSpacing(2)

            // Student Text Editor
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text("Your Written Response:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Write in AP style")
                        .font(.system(size: 9))
                        .foregroundColor(.purple)
                }

                TextEditor(text: $studentInput)
                    .font(.system(size: 11, design: .monospaced))
                    .frame(minHeight: 85, maxHeight: 115)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.systemBackground)))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.purple.opacity(0.3), lineWidth: 1))
            }

            // Check Rubric Button (Bouncy style)
            Button(action: onEvaluate) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                    Text("Check Against AP Rubric (+50 XP)")
                }
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(
                    LinearGradient(colors: [.purple, .indigo], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .bouncyButton()
            .disabled(studentInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            // AP Rubric Breakdown Result
            if isEvaluated || question.isAnswered {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        HStack(spacing: 4) {
                            Text("Official AP Scoring Rubric")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .foregroundColor(.purple)
                            Text("• \(question.earnedPoints == question.maxPoints ? "Cooked it! 🔥" : "Solid Attempt 💪")")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(question.earnedPoints == question.maxPoints ? .green : .orange)
                        }

                        Spacer()

                        Text("Score: \(question.earnedPoints) / \(question.maxPoints) pts")
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding(.bottom, 2)

                    VStack(spacing: 6) {
                        ForEach(question.rubricPoints.sorted { $0.pointNumber < $1.pointNumber }) { rubricPoint in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: rubricPoint.isEarned ? "checkmark.circle.fill" : "circle.dashed")
                                    .font(.system(size: 12))
                                    .foregroundColor(rubricPoint.isEarned ? .green : .secondary.opacity(0.6))
                                    .padding(.top, 1)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(rubricPoint.criteriaTitle)
                                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                        .foregroundColor(rubricPoint.isEarned ? .green : .primary)
                                    Text(rubricPoint.requirementDescription)
                                        .font(.system(size: 9))
                                        .foregroundColor(.primary.opacity(0.85))
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(rubricPoint.isEarned ? Color.green.opacity(0.1) : Color.primary.opacity(0.03))
                            )
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.purple.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.purple.opacity(0.35), lineWidth: 1.5)
                )
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
        }
        .padding(14)
        .kognitCard(cornerRadius: 18)
    }
}
