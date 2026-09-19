# Kognit

**AI-powered study suite transforming course documents into slides, active recall flashcards, and adaptive mock tests.**

## Overview
Kognit is an offline-first iOS application designed for high school and collegiate students. Students upload or photograph their study materials (syllabi, lecture notes, textbook chapters, worksheets), and Kognit automatically synthesizes:
- **Slide Decks:** Digestible chapter and concept summaries with formula highlights and exam trap warnings.
- **Active Recall Flashcards:** Native 3D flashcards powered by the **FSRS-4.5** (Free Spaced Repetition Scheduler) memory engine.
- **Adaptive Mock Exams:** Stimulus-based multiple choice and free response questions (FRQs) with automated rubric grading.

## Architecture
- **Client:** Native iOS 18 (Swift 6, SwiftUI, SwiftData for offline caching).
- **Backend:** FastAPI (Python), Supabase (PostgreSQL 16, pgvector), Google Gemini 1.5 Flash.
- **Sync:** Monotonic revision vectors with client mutation logs and deterministic FSRS event replay.

## License
MIT
