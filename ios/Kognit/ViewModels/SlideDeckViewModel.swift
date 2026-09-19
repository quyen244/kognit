import SwiftUI
import SwiftData

@Observable
@MainActor
public final class SlideDeckViewModel {
    public var slides: [SlideEntity] = []
    public var currentSlideIndex: Int = 0
    public var selectedFormulaTerm: FormulaTermEntity? = nil

    public var currentSlide: SlideEntity? {
        guard !slides.isEmpty, currentSlideIndex >= 0, currentSlideIndex < slides.count else { return nil }
        return slides[currentSlideIndex]
    }

    public var progressText: String {
        guard !slides.isEmpty else { return "0 / 0" }
        return "\(currentSlideIndex + 1) / \(slides.count)"
    }

    public var canGoBack: Bool {
        currentSlideIndex > 0
    }

    public var canGoForward: Bool {
        currentSlideIndex < slides.count - 1
    }

    public init(slides: [SlideEntity] = []) {
        self.slides = slides
    }

    public func setSlides(_ newSlides: [SlideEntity]) {
        self.slides = newSlides
        self.currentSlideIndex = 0
        self.selectedFormulaTerm = nil
    }

    public func nextSlide() {
        if canGoForward {
            currentSlideIndex += 1
            selectedFormulaTerm = nil
        }
    }

    public func prevSlide() {
        if canGoBack {
            currentSlideIndex -= 1
            selectedFormulaTerm = nil
        }
    }

    public func goToSlide(index: Int) {
        if index >= 0 && index < slides.count {
            currentSlideIndex = index
            selectedFormulaTerm = nil
        }
    }

    public func selectFormulaTerm(_ term: FormulaTermEntity) {
        if selectedFormulaTerm?.id == term.id {
            selectedFormulaTerm = nil
        } else {
            selectedFormulaTerm = term
        }
    }

    public func toggleAudioNarration() {
        guard let slide = currentSlide else { return }
        let textToRead = "\(slide.title). \(slide.summary). Key points: \(slide.bulletPoints.joined(separator: ". "))"
        AudioNarrationService.shared.toggle(text: textToRead, slideId: slide.id)
    }
}
