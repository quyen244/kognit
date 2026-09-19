import SwiftUI
import SwiftData
import UniformTypeIdentifiers

#if canImport(VisionKit)
import VisionKit
#endif

public struct DocumentIngestionView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = DocumentIngestionViewModel()
    @State private var flashActive: Bool = false
    @State private var burstCount: Int = 3

    var onIngestionComplete: () -> Void

    public init(onIngestionComplete: @escaping () -> Void = {}) {
        self.onIngestionComplete = onIngestionComplete
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header Subtitle & Badge
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Scan or Import Material")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                            Text("Real-time edge detection & MathPix OCR")
                                .font(.system(size: 10.5))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        KognitBadge("VNDocumentCamera ⚡", color: .blue)
                    }

                    // MARK: - Method Switcher Tabs
                    HStack(spacing: 6) {
                        TabButton(
                            title: "Camera Scanner",
                            icon: "camera.fill",
                            isSelected: viewModel.activeTab == .camera
                        ) {
                            viewModel.activeTab = .camera
                        }

                        TabButton(
                            title: "PDF / PPTX Picker",
                            icon: "doc.fill",
                            isSelected: viewModel.activeTab == .filePicker
                        ) {
                            viewModel.activeTab = .filePicker
                        }
                    }
                    .padding(4)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.tertiarySystemBackground)))

                    // MARK: - Content by Tab
                    if viewModel.activeTab == .camera {
                        cameraScannerSection
                    } else {
                        filePickerSection
                    }

                    // MARK: - Pipeline Status Section
                    if viewModel.isProcessing || viewModel.currentStage == .complete {
                        PipelineStatusView(
                            currentStage: viewModel.currentStage,
                            overallProgress: viewModel.overallProgress,
                            estimatedSecondsRemaining: viewModel.estimatedSecondsRemaining,
                            onCancel: {
                                viewModel.cancelIngestion()
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 30)
            }
            .navigationTitle("Document Ingestion")
            .navigationBarTitleDisplayMode(.inline)
            #if canImport(VisionKit) && canImport(UIKit)
            .sheet(isPresented: $viewModel.isPresentingScanner) {
                DocumentScannerRepresentable(scannedPages: $viewModel.scannedPages)
            }
            #endif
            .fileImporter(
                isPresented: $viewModel.isPresentingFilePicker,
                allowedContentTypes: [.pdf, .presentation, .image],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        viewModel.selectedFileName = url.lastPathComponent
                        viewModel.selectedFileSize = "3.8 MB"
                    }
                case .failure(let error):
                    print("File picker error: \(error.localizedDescription)")
                }
            }
            .alert("AI Extraction Complete! 🎉", isPresented: $viewModel.showCompletionAlert) {
                Button("View Study Decks") {
                    onIngestionComplete()
                }
            } message: {
                Text("Synthesized 18 Slides, 24 Flashcards, and 1 Timed Mock Exam with distractor rationales and AP scoring rubrics.")
            }
        }
    }

    // MARK: - Camera Scanner Section
    @ViewBuilder
    private var cameraScannerSection: some View {
        VStack(spacing: 12) {
            // Viewfinder Container
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.black)
                    .frame(height: 230)

                // Viewfinder Corners
                ViewfinderOverlay()

                VStack(spacing: 0) {
                    // Top Diagnostics Pill & Controls
                    HStack {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.green)
                            Text("98% Legibility (Good Light)")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.black.opacity(0.75)))

                        Spacer()

                        HStack(spacing: 8) {
                            Button(action: {
                                flashActive.toggle()
                                HapticsService.shared.light()
                            }) {
                                Image(systemName: flashActive ? "bolt.fill" : "bolt.slash.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(flashActive ? .yellow : .white)
                                    .frame(width: 26, height: 26)
                                    .background(Circle().fill(Color.black.opacity(0.65)))
                            }
                            .bouncyButton()

                            Button(action: {
                                HapticsService.shared.light()
                            }) {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white)
                                    .frame(width: 26, height: 26)
                                    .background(Circle().fill(Color.black.opacity(0.65)))
                            }
                            .bouncyButton()
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 12)

                    Spacer()

                    // Simulated Note Sheet
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("BIO 101 - MITOSIS")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(.indigo)
                            Spacer()
                            Text("p. 42")
                                .font(.system(size: 7.5, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.bottom, 2)
                        .overlay(Rectangle().frame(height: 0.5).foregroundColor(.gray.opacity(0.3)), alignment: .bottom)

                        Text("1. Prophase: Chromosomes condense")
                            .font(.system(size: 7.5, design: .monospaced))
                            .foregroundColor(.black.opacity(0.8))
                        Text("2. Metaphase: Equator alignment")
                            .font(.system(size: 7.5, design: .monospaced))
                            .foregroundColor(.black.opacity(0.8))
                        Text("3. Anaphase: Sister chromatids pull")
                            .font(.system(size: 7.5, design: .monospaced))
                            .foregroundColor(.black.opacity(0.8))
                    }
                    .padding(10)
                    .frame(width: 180)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color(hex: "#FFFBEB")))
                    .rotationEffect(.degrees(-1))
                    .shadow(color: .black.opacity(0.25), radius: 5)

                    Spacer()

                    // Bottom Shutter & Controls
                    HStack {
                        Text("Page \(burstCount) of 5")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.black.opacity(0.65)))

                        Spacer()

                        // Large Shutter Button (50pt)
                        Button(action: {
                            burstCount += 1
                            HapticsService.shared.heavy()
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                                    .frame(width: 44, height: 44)
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 34, height: 34)
                            }
                        }
                        .bouncyButton(scaleAmount: 0.88)

                        Spacer()

                        Button(action: {
                            HapticsService.shared.medium()
                            viewModel.startIngestionPipeline(modelContext: modelContext)
                        }) {
                            HStack(spacing: 4) {
                                Text("Done")
                                Image(systemName: "checkmark")
                            }
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.blue))
                            .foregroundColor(.white)
                        }
                        .bouncyButton()
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }

            // Filter Pills (44pt target)
            HStack(spacing: 8) {
                ForEach(DocumentIngestionViewModel.ScannerFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        viewModel.selectedFilter = filter
                        HapticsService.shared.light()
                    }) {
                        Text(filter.rawValue)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(viewModel.selectedFilter == filter ? Color.blue : Color(UIColor.tertiarySystemBackground))
                            )
                            .foregroundColor(viewModel.selectedFilter == filter ? .white : .primary)
                    }
                    .bouncyButton()
                }
            }

            #if canImport(VisionKit) && canImport(UIKit)
            if VNDocumentCameraViewController.isSupported {
                Button(action: {
                    viewModel.isPresentingScanner = true
                }) {
                    Label("Launch Full Camera Viewfinder", systemImage: "camera.fill")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.blue.opacity(0.15)))
                        .foregroundColor(.blue)
                }
                .bouncyButton()
            }
            #endif
        }
    }

    // MARK: - File Picker Section
    @ViewBuilder
    private var filePickerSection: some View {
        VStack(spacing: 14) {
            // Drop Zone Card
            Button(action: {
                viewModel.isPresentingFilePicker = true
            }) {
                VStack(spacing: 10) {
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)

                    Text("Select PDF or PPTX")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Tap to browse Files app or iCloud Drive")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                        .foregroundColor(Color.blue.opacity(0.5))
                        .background(RoundedRectangle(cornerRadius: 16).fill(Color.blue.opacity(0.04)))
                )
            }
            .bouncyButton()

            // Selected Document Card
            HStack(spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 26))
                    .foregroundColor(.red)

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedFileName ?? "Document.pdf")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .lineLimit(1)
                    Text("\(viewModel.selectedFileSize ?? "4.2 MB") • \(viewModel.selectedFilePageCount) Pages • \(viewModel.selectedCourse)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }

                Spacer()

                KognitBadge("Ready ⚡", color: .green)
            }
            .padding(14)
            .kognitCard(cornerRadius: 14)

            // Process Button (48pt touch target with bouncy style)
            Button(action: {
                viewModel.startIngestionPipeline(modelContext: modelContext)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                    Text("Start AI Extraction Pipeline")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .bouncyButton()
            .disabled(viewModel.isProcessing)
        }
    }
}

// MARK: - Tab Button Component
private struct TabButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .black : .medium, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(RoundedRectangle(cornerRadius: 10).fill(isSelected ? Color.blue : Color.clear))
            .foregroundColor(isSelected ? .white : .secondary)
        }
        .bouncyButton(scaleAmount: 0.96)
    }
}

// MARK: - Viewfinder Corner Overlay
private struct ViewfinderOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let cornerLength: CGFloat = 22
            let lineWidth: CGFloat = 3
            let padding: CGFloat = 12

            // Top-Left
            Path { path in
                path.move(to: CGPoint(x: padding, y: padding + cornerLength))
                path.addLine(to: CGPoint(x: padding, y: padding))
                path.addLine(to: CGPoint(x: padding + cornerLength, y: padding))
            }
            .stroke(Color.cyan, lineWidth: lineWidth)

            // Top-Right
            Path { path in
                path.move(to: CGPoint(x: geo.size.width - padding - cornerLength, y: padding))
                path.addLine(to: CGPoint(x: geo.size.width - padding, y: padding))
                path.addLine(to: CGPoint(x: geo.size.width - padding, y: padding + cornerLength))
            }
            .stroke(Color.cyan, lineWidth: lineWidth)

            // Bottom-Left
            Path { path in
                path.move(to: CGPoint(x: padding, y: geo.size.height - padding - cornerLength))
                path.addLine(to: CGPoint(x: padding, y: geo.size.height - padding))
                path.addLine(to: CGPoint(x: padding + cornerLength, y: geo.size.height - padding))
            }
            .stroke(Color.cyan, lineWidth: lineWidth)

            // Bottom-Right
            Path { path in
                path.move(to: CGPoint(x: geo.size.width - padding - cornerLength, y: geo.size.height - padding))
                path.addLine(to: CGPoint(x: geo.size.width - padding, y: geo.size.height - padding))
                path.addLine(to: CGPoint(x: geo.size.width - padding, y: geo.size.height - padding - cornerLength))
            }
            .stroke(Color.cyan, lineWidth: lineWidth)
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
