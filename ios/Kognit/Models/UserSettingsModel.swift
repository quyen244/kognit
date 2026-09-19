import Foundation
import SwiftData

@Model
public final class UserSettingsEntity {
    @Attribute(.unique) public var id: UUID
    public var studentName: String
    public var streakCount: Int
    public var lastStudyDate: Date
    public var curriculumLevel: String
    public var targetExamDate: Date
    public var spacedRepetitionAlgorithm: String
    public var distractorAggressiveness: Int // 1 to 5
    public var formulaRenderMode: String
    public var projectedScore: String
    public var masteryPercentage: Int
    public var cellEnergyMastery: Int
    public var geneticsMastery: Int

    public init(
        id: UUID = UUID(),
        studentName: String = "Alex",
        streakCount: Int = 12,
        lastStudyDate: Date = Date(),
        curriculumLevel: String = "AP Biology / AP Chemistry (High School)",
        targetExamDate: Date = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date(),
        spacedRepetitionAlgorithm: String = "FSRS-4.5 (Free Spaced Repetition Scheduler)",
        distractorAggressiveness: Int = 4,
        formulaRenderMode: String = "Interactive LaTeX Pills",
        projectedScore: String = "4.4 / 5.0",
        masteryPercentage: Int = 78,
        cellEnergyMastery: Int = 85,
        geneticsMastery: Int = 72
    ) {
        self.id = id
        self.studentName = studentName
        self.streakCount = streakCount
        self.lastStudyDate = lastStudyDate
        self.curriculumLevel = curriculumLevel
        self.targetExamDate = targetExamDate
        self.spacedRepetitionAlgorithm = spacedRepetitionAlgorithm
        self.distractorAggressiveness = distractorAggressiveness
        self.formulaRenderMode = formulaRenderMode
        self.projectedScore = projectedScore
        self.masteryPercentage = masteryPercentage
        self.cellEnergyMastery = cellEnergyMastery
        self.geneticsMastery = geneticsMastery
    }
}
