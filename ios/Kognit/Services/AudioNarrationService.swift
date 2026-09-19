import Foundation
import AVFoundation

@Observable
public final class AudioNarrationService: NSObject, AVSpeechSynthesizerDelegate, @unchecked Sendable {
    public static let shared = AudioNarrationService()

    public var isPlaying: Bool = false
    public var isPaused: Bool = false
    public var currentSlideId: UUID?

    private let synthesizer = AVSpeechSynthesizer()

    public override init() {
        super.init()
        synthesizer.delegate = self
    }

    public func toggle(text: String, slideId: UUID? = nil) {
        if isPlaying {
            if isPaused {
                resume()
            } else if currentSlideId == slideId {
                pause()
            } else {
                stop()
                speak(text: text, slideId: slideId)
            }
        } else {
            speak(text: text, slideId: slideId)
        }
    }

    public func speak(text: String, slideId: UUID? = nil, rate: Float = 0.52) {
        stop()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        utterance.volume = 1.0

        currentSlideId = slideId
        isPlaying = true
        isPaused = false

        synthesizer.speak(utterance)
    }

    public func pause() {
        if synthesizer.pauseSpeaking(at: .word) {
            isPaused = true
        }
    }

    public func resume() {
        if synthesizer.continueSpeaking() {
            isPaused = false
        }
    }

    public func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isPlaying = false
        isPaused = false
        currentSlideId = nil
    }

    // MARK: - AVSpeechSynthesizerDelegate
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isPlaying = false
        isPaused = false
        currentSlideId = nil
    }

    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isPlaying = false
        isPaused = false
        currentSlideId = nil
    }
}
