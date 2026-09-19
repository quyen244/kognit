import SwiftUI

public struct PipelineStatusView: View {
    public let currentStage: PipelineStage
    public let overallProgress: Double
    public let estimatedSecondsRemaining: Int
    public let onCancel: () -> Void

    public init(
        currentStage: PipelineStage,
        overallProgress: Double,
        estimatedSecondsRemaining: Int,
        onCancel: @escaping () -> Void = {}
    ) {
        self.currentStage = currentStage
        self.overallProgress = overallProgress
        self.estimatedSecondsRemaining = estimatedSecondsRemaining
        self.onCancel = onCancel
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: currentStage.isTerminal ? "checkmark.circle.fill" : "gearshape.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                        .symbolEffect(.rotate, isActive: !currentStage.isTerminal)

                    Text(currentStage.isTerminal ? "Processing Complete!" : "Processing Document...")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.blue)
                }

                Spacer()

                Text("\(Int(overallProgress * 100))%")
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundColor(.blue)
            }

            // Progress Bar
            ProgressView(value: overallProgress, total: 1.0)
                .tint(.blue)
                .scaleEffect(x: 1, y: 1.5, anchor: .center)

            // Stage Steps
            VStack(spacing: 6) {
                StageStepRow(
                    stepNumber: 1,
                    title: "Document Upload & Virus Scan",
                    isComplete: overallProgress >= 0.25,
                    isActive: currentStage == .uploading
                )

                StageStepRow(
                    stepNumber: 2,
                    title: "Vision OCR & MathPix Extraction",
                    isComplete: overallProgress >= 0.55,
                    isActive: currentStage == .ocr
                )

                StageStepRow(
                    stepNumber: 3,
                    title: "Semantic Chunking & RAG Indexing",
                    isComplete: overallProgress >= 0.85,
                    isActive: currentStage == .chunking
                )

                StageStepRow(
                    stepNumber: 4,
                    title: "AI Synthesis (Slides, Cards, Exam)",
                    isComplete: overallProgress >= 1.0,
                    isActive: currentStage == .synthesizing
                )
            }

            // Bottom Estimated Time
            HStack {
                if !currentStage.isTerminal {
                    Text("Estimated time remaining: ~\(max(1, estimatedSecondsRemaining)) seconds")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                } else {
                    Text("18 Slides, 24 Flashcards & Mock Exam generated!")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.green)
                }

                Spacer()

                if !currentStage.isTerminal {
                    Button("Cancel", action: onCancel)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.red)
                }
            }
            .padding(.top, 2)
        }
        .padding(14)
        .kognitCard(borderColor: Color.blue.opacity(0.3))
    }
}

// MARK: - Stage Step Row
private struct StageStepRow: View {
    let stepNumber: Int
    let title: String
    let isComplete: Bool
    let isActive: Bool

    var body: some View {
        HStack(spacing: 8) {
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.green)
            } else if isActive {
                ProgressView()
                    .scaleEffect(0.6)
                    .frame(width: 11, height: 11)
            } else {
                Image(systemName: "circle")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.4))
            }

            Text("\(stepNumber). \(title)")
                .font(.system(size: 10, weight: isActive ? .bold : .regular))
                .foregroundColor(isActive ? .blue : (isComplete ? .primary : .secondary.opacity(0.6)))

            Spacer()

            Text(isComplete ? "100%" : (isActive ? "In Progress" : "Queued"))
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(isComplete ? .green : (isActive ? .blue : .secondary.opacity(0.5)))
        }
    }
}
