import SwiftUI
import SwiftData

@main
struct KognitApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                DocumentEntity.self,
                SlideDeckEntity.self,
                SlideEntity.self,
                FormulaTermEntity.self,
                FlashcardEntity.self,
                ExamEntity.self,
                ExamQuestionEntity.self,
                OptionEntity.self,
                RubricPointEntity.self,
                ExamResultEntity.self,
                UserSettingsEntity.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            self.container = try ModelContainer(for: schema, configurations: [config])

            // Seed initial sample data if empty
            Task { @MainActor in
                SampleDataService.populateInitialDataIfNeeded(context: container.mainContext)
            }
        } catch {
            fatalError("Could not initialize SwiftData ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(container)
    }
}
