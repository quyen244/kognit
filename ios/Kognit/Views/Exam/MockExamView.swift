import SwiftUI
import SwiftData

public struct MockExamView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var exams: [ExamEntity]
    @State private var viewModel = MockExamViewModel()

    public init() {}

    private var currentExam: ExamEntity? {
        exams.first
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                if let result = viewModel.examResult, viewModel.examSubmitted {
                    ExamResultsView(
                        result: result,
                        standard: viewModel.exam?.standard ?? .ap,
                        onRestart: {
                            viewModel.restartExam()
                        }
                    )
                } else if viewModel.questions.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "stopwatch.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Mock Exams Available")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text("Ingest a document to generate an AP / SAT mock exam.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    // Header with Title & Countdown Timer
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentExam?.title ?? "Diagnostic Mock Exam")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .lineLimit(1)
                            Text(currentExam?.course ?? "AP Biology")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        ExamTimerView(
                            remainingSeconds: viewModel.remainingSeconds,
                            isWarning: viewModel.isTimerWarning
                        )
                    }
                    .padding(.horizontal, 16)

                    // Question Type Switcher: MCQ vs FRQ
                    HStack(spacing: 4) {
                        ExamTabButton(
                            title: "Multiple Choice (MCQ)",
                            isSelected: viewModel.activeSection == .mcq
                        ) {
                            viewModel.switchSection(.mcq)
                        }

                        ExamTabButton(
                            title: "Free Response (FRQ)",
                            isSelected: viewModel.activeSection == .frq
                        ) {
                            viewModel.switchSection(.frq)
                        }
                    }
                    .padding(3)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(UIColor.tertiarySystemBackground)))
                    .padding(.horizontal, 16)

                    // Question Content ScrollView
                    ScrollView {
                        VStack(spacing: 12) {
                            if let question = viewModel.currentQuestion {
                                if question.questionType == .mcq {
                                    MCQQuestionView(question: question) { option in
                                        viewModel.selectOption(option, modelContext: modelContext)
                                    }
                                } else {
                                    FRQQuestionView(
                                        question: question,
                                        studentInput: $viewModel.frqStudentInput,
                                        isEvaluated: viewModel.frqRubricEvaluated,
                                        onEvaluate: {
                                            viewModel.evaluateFRQ(modelContext: modelContext)
                                        }
                                    )
                                }
                            } else {
                                Text("No questions in this section.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding()
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    // Navigation Controls & Submit
                    HStack {
                        Button(action: {
                            if viewModel.currentIndex > 0 {
                                viewModel.currentIndex -= 1
                                viewModel.frqStudentInput = viewModel.currentQuestion?.studentAnswerText ?? ""
                                viewModel.frqRubricEvaluated = viewModel.currentQuestion?.isAnswered ?? false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Prev Q")
                            }
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                        }
                        .bouncyButton()
                        .disabled(viewModel.currentIndex == 0)
                        .opacity(viewModel.currentIndex == 0 ? 0.3 : 1.0)

                        Spacer()

                        Button(action: {
                            viewModel.submitExam()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "flag.checkered")
                                Text("Submit Exam ⚡")
                            }
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(Capsule())
                        }
                        .bouncyButton()

                        Spacer()

                        Button(action: {
                            if viewModel.currentIndex < viewModel.filteredQuestions.count - 1 {
                                viewModel.currentIndex += 1
                                viewModel.frqStudentInput = viewModel.currentQuestion?.studentAnswerText ?? ""
                                viewModel.frqRubricEvaluated = viewModel.currentQuestion?.isAnswered ?? false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Text("Next Q")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Capsule().stroke(Color.primary.opacity(0.2), lineWidth: 1))
                        }
                        .bouncyButton()
                        .disabled(viewModel.currentIndex >= viewModel.filteredQuestions.count - 1)
                        .opacity(viewModel.currentIndex >= viewModel.filteredQuestions.count - 1 ? 0.3 : 1.0)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("AP Mock Exam")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let exam = currentExam {
                    viewModel.setExam(exam)
                }
            }
            .onChange(of: exams) { _, newExams in
                if let exam = newExams.first {
                    viewModel.setExam(exam)
                }
            }
        }
    }
}

// MARK: - Exam Tab Button Component
private struct ExamTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 11, weight: isSelected ? .black : .medium, design: .rounded))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.blue : Color.clear)
                )
                .foregroundColor(isSelected ? .white : .secondary)
        }
        .bouncyButton(scaleAmount: 0.96)
    }
}
