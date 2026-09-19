# Kognit iOS - AI Document-to-Study Suite

A native **iOS 18+** study application built with **SwiftUI**, **SwiftData**, and **Swift 6**. Kognit transforms class notes, textbook photos, and lecture slide decks into high-retention study modalities for high school STEM (AP Biology, AP Chemistry, and SAT prep).

---

## 📱 Core Modules & Architecture

### 1. Document Ingestion
- **VisionKit Camera Scanner**: Native burst scanning using `VNDocumentCameraViewController` with real-time perspective correction, contrast enhancement for handwritten pencil notes, and legibility diagnostics (`DocumentScannerRepresentable.swift`).
- **File Picker**: `fileImporter` supporting PDF and PPTX slide decks (`DocumentIngestionView.swift`).
- **Multi-Stage Pipeline Tracker**: Real-time progress monitoring through 4 stages: Document Upload -> Vision OCR & MathPix -> Semantic Chunking & Vector RAG -> AI Synthesis (`PipelineStatusView.swift`).

### 2. Active Recall Flashcards & FSRS-4.5
- **3D Card Flip Mechanics**: Native SwiftUI gesture-driven 3D rotation using `rotation3DEffect` with backface hiding, spring physics, and haptic feedback (`Flashcard3DCardView.swift`).
- **FSRS-4.5 Algorithm**: Pure Swift implementation of the Free Spaced Repetition Scheduler 4.5 (`FSRSScheduler.swift`). Computes memory stability ($S$), item difficulty ($D$), and retrievability ($R$), predicting optimal intervals for **Again (< 10m)**, **Hard (12h)**, **Good (1d)**, and **Easy (4d)** (`FSRSRatingButtonsView.swift`).
- **Offline Persistence**: Retains spaced repetition parameters directly in SwiftData (`FlashcardEntity`).

### 3. Slide Deck Summaries & Formula Highlights
- **Paged Carousel**: Fluid `TabView` with `.page(indexDisplayMode: .never)`, animated progress dot capsules, and previous/next navigation (`SlideDeckViewer.swift`).
- **Formula Stoichiometry**: Interactive chemical and mathematical equation viewer (`FormulaHighlightView.swift`) with tappable reactant/product pills (e.g., $C_6H_{12}O_6$, $6O_2$, $32\text{ ATP}$) and detailed popover explanations.
- **Audio Readout**: Hands-free voice synthesis using `AVSpeechSynthesizer` (`AudioNarrationService.swift`).
- **AP Exam Trap Callouts**: Highlights common test-day pitfalls on every slide.

### 4. Timed Mock Exams with AP & SAT Rubrics
- **Countdown Timer**: Real-time test timer with warning animations when under 2 minutes (`ExamTimerView.swift`).
- **Stimulus-Based MCQs**: 4-option multiple-choice questions with authentic distractor rationales explaining why incorrect options are common student misconceptions (`MCQQuestionView.swift`).
- **Multi-Point FRQ Rubric Evaluation**: Free-response questions with official 4-point AP scoring rubrics and keyword/mechanistic matching (`FRQQuestionView.swift`).
- **Scaled Score Engine**: Converts raw points into official AP (1.0 to 5.0) and SAT (200 to 800) scores (`ExamResultsView.swift`).

### 5. Async API Client for Backend Jobs
- **Multipart Upload**: Streams documents, PDFs, and slide decks to `POST /api/v1/documents/upload` (`APIClient.swift`).
- **Job Polling Engine**: Async/await polling loop with backoff and cancellation for `GET /api/v1/jobs/{id}`.
- **Offline Simulation Mode**: Includes a simulation mode that allows the app to be fully interactive and testable offline without an external backend cluster.

---

## 📂 Project Structure

```
kognit-ios/
├── Package.swift
├── Kognit/
│   ├── KognitApp.swift                      # App entry point & SwiftData initialization
│   ├── Models/
│   │   ├── DocumentModel.swift              # DocumentEntity, PipelineStage, DocumentPayload
│   │   ├── FlashcardModel.swift             # FlashcardEntity, FSRSRating, FSRSState
│   │   ├── SlideDeckModel.swift             # SlideDeckEntity, SlideEntity, FormulaTermEntity
│   │   ├── ExamModel.swift                  # ExamEntity, ExamQuestionEntity, RubricPointEntity
│   │   └── UserSettingsModel.swift          # UserSettingsEntity, streak, curriculum target
│   ├── Services/
│   │   ├── APIClient.swift                  # Async URLSession client & job polling engine
│   │   ├── FSRSScheduler.swift              # Complete FSRS-4.5 spaced repetition scheduler
│   │   ├── AudioNarrationService.swift      # AVSpeechSynthesizer audio readout service
│   │   ├── SampleDataService.swift          # AP Biology diagnostic sample data
│   │   └── SwiftDataPreviewContainer.swift  # In-memory container for previews & testing
│   ├── ViewModels/
│   │   ├── DocumentIngestionViewModel.swift # Scanner, file picker & upload pipeline state
│   │   ├── FlashcardDeckViewModel.swift     # 3D flip, FSRS review logic & session tracking
│   │   ├── SlideDeckViewModel.swift         # Paged viewer, formula pills & narration
│   │   └── MockExamViewModel.swift          # Timed exam, MCQ distractors & FRQ grading
│   └── Views/
│       ├── MainTabView.swift                # iOS bottom navigation bar (Home, Scan, Slides, Cards, Exam)
│       ├── Components/                      # Common cards, badges, streak indicators
│       ├── Home/                            # Dashboard, streak counter & mastery gauge
│       ├── Ingestion/                       # VisionKit scanner, file picker & pipeline status
│       ├── Slides/                          # Paged slide viewer & formula highlights
│       ├── Flashcards/                      # 3D flip cards & FSRS rating buttons
│       └── Exam/                            # Timed test, stimulus MCQs & FRQ rubrics
└── Tests/
    └── FSRSSchedulerTests.swift             # Unit tests for FSRS-4.5 scheduling
```

---

## 🛠️ Requirements & Setup

- **Target OS**: iOS 18.0+ / iPadOS 18.0+ / macOS 15.0+ (Designed with iPad & Mac Catalyst compatibility)
- **Toolchain**: Swift 6.0 / Xcode 16.0+
- **Frameworks**: `SwiftUI`, `SwiftData`, `VisionKit`, `AVFoundation`, `UniformTypeIdentifiers`

### Opening in Xcode:
1. Open Xcode and select **Open Existing Project or Package**.
2. Select the `C:\Users\Admin\.gemini\antigravity-cli\scratch\kognit-ios` directory (or open `Package.swift`).
3. Select an iOS 18 Simulator (e.g. iPhone 16 Pro) or physical iOS device and press **Cmd+R** to run.
