import SwiftUI
import SwiftData

public struct SlideDeckViewer: View {
    @Query private var slideDecks: [SlideDeckEntity]
    @State private var viewModel = SlideDeckViewModel()

    public init() {}

    private var currentDeck: SlideDeckEntity? {
        slideDecks.first
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                if viewModel.slides.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.below.ecg.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No Slide Decks Available")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                        Text("Ingest a document to generate visual concept slides.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    // Header Counter & Audio Readout
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentDeck?.title ?? "Course Slide Deck")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .lineLimit(1)
                            Text(currentDeck?.course ?? "AP Biology")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            KognitBadge(viewModel.progressText, color: .purple)

                            // Audio Readout Button (44pt target)
                            Button(action: {
                                viewModel.toggleAudioNarration()
                            }) {
                                Image(systemName: AudioNarrationService.shared.isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 15))
                                    .foregroundColor(AudioNarrationService.shared.isPlaying ? .green : .purple)
                                    .frame(width: 38, height: 38)
                                    .background(Circle().fill(Color(UIColor.secondarySystemBackground)))
                                    .overlay(
                                        Circle()
                                            .stroke(AudioNarrationService.shared.isPlaying ? Color.green : Color.purple.opacity(0.3), lineWidth: 1.5)
                                    )
                            }
                            .bouncyButton()
                        }
                    }
                    .padding(.horizontal, 16)

                    // Paged TabView for Slides
                    TabView(selection: $viewModel.currentSlideIndex) {
                        ForEach(Array(viewModel.slides.enumerated()), id: \.element.id) { index, slide in
                            SlideCardView(slide: slide, selectedTerm: $viewModel.selectedFormulaTerm)
                                .tag(index)
                                .padding(.horizontal, 16)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))

                    // Bottom Navigation Controls
                    HStack {
                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                viewModel.prevSlide()
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "chevron.left")
                                Text("Prev")
                            }
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .padding(.horizontal, 14)
                            .frame(height: 44)
                            .background(Capsule().stroke(Color.primary.opacity(0.2), lineWidth: 1.5))
                        }
                        .bouncyButton()
                        .disabled(!viewModel.canGoBack)
                        .opacity(viewModel.canGoBack ? 1.0 : 0.3)

                        Spacer()

                        // Progress Capsules
                        HStack(spacing: 6) {
                            ForEach(0..<viewModel.slides.count, id: \.self) { idx in
                                Capsule()
                                    .fill(idx == viewModel.currentSlideIndex ? Color.purple : Color.primary.opacity(0.15))
                                    .frame(width: idx == viewModel.currentSlideIndex ? 22 : 6, height: 6)
                                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: viewModel.currentSlideIndex)
                            }
                        }

                        Spacer()

                        Button(action: {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                viewModel.nextSlide()
                            }
                        }) {
                            HStack(spacing: 5) {
                                Text("Next")
                                Image(systemName: "chevron.right")
                            }
                            .font(.system(size: 12, weight: .black, design: .rounded))
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .background(
                                LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                            )
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                        .bouncyButton()
                        .disabled(!viewModel.canGoForward)
                        .opacity(viewModel.canGoForward ? 1.0 : 0.3)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .navigationTitle("Slide Deck")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let deck = currentDeck {
                    viewModel.setSlides(deck.slides.sorted { $0.slideIndex < $1.slideIndex })
                }
            }
            .onChange(of: slideDecks) { _, newDecks in
                if let deck = newDecks.first {
                    viewModel.setSlides(deck.slides.sorted { $0.slideIndex < $1.slideIndex })
                }
            }
            .onDisappear {
                AudioNarrationService.shared.stop()
            }
        }
    }
}
