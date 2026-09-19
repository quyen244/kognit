import SwiftUI

public struct MainTabView: View {
    @State private var selectedTab: Int = 0

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(
                selectedTab: $selectedTab,
                onOpenScanner: { selectedTab = 1 },
                onOpenSlides: { selectedTab = 2 },
                onOpenCards: { selectedTab = 3 },
                onOpenExam: { selectedTab = 4 }
            )
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            DocumentIngestionView {
                selectedTab = 2 // Switch to Slides after ingestion
            }
            .tabItem {
                Label("Scan", systemImage: "camera.viewfinder")
            }
            .tag(1)

            SlideDeckViewer()
                .tabItem {
                    Label("Slides", systemImage: "doc.text.below.ecg.fill")
                }
                .tag(2)

            FlashcardDeckView()
                .tabItem {
                    Label("Cards", systemImage: "rectangle.portrait.on.rectangle.portrait.angled.fill")
                }
                .tag(3)

            MockExamView()
                .tabItem {
                    Label("Exam", systemImage: "stopwatch.fill")
                }
                .tag(4)
        }
        .tint(.blue)
    }
}
