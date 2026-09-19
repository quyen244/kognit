import Foundation
import SwiftData

@MainActor
public struct SwiftDataPreviewContainer {
    public static let shared: ModelContainer = {
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
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            SampleDataService.populateInitialDataIfNeeded(context: container.mainContext)
            return container
        } catch {
            fatalError("Could not create in-memory ModelContainer: \(error)")
        }
    }()
}
