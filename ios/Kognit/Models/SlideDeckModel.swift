import Foundation
import SwiftData

// MARK: - Slide Type
public enum SlideType: String, Codable, CaseIterable, Sendable {
    case keyConcept = "Key Concept"
    case formulaHighlight = "Formula Highlight"
    case digestibleSummary = "Digestible Summary"

    public var badgeColorHex: String {
        switch self {
        case .keyConcept: return "#3B82F6"      // primary blue
        case .formulaHighlight: return "#8B5CF6" // secondary purple
        case .digestibleSummary: return "#10B981"// accent emerald
        }
    }
}

// MARK: - SwiftData Formula Term Entity
@Model
public final class FormulaTermEntity {
    @Attribute(.unique) public var id: UUID
    public var symbol: String
    public var name: String
    public var explanation: String
    public var colorHex: String
    
    public var slide: SlideEntity?

    public init(
        id: UUID = UUID(),
        symbol: String,
        name: String,
        explanation: String,
        colorHex: String = "#3B82F6"
    ) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.explanation = explanation
        self.colorHex = colorHex
    }
}

// MARK: - SwiftData Slide Entity
@Model
public final class SlideEntity {
    @Attribute(.unique) public var id: UUID
    public var slideIndex: Int
    public var slideIdTag: String
    public var slideTypeRaw: String
    public var title: String
    public var summary: String
    public var bulletPoints: [String]
    public var apExamTrap: String?
    public var equationString: String?
    
    @Relationship(deleteRule: .cascade, inverse: \FormulaTermEntity.slide)
    public var formulaTerms: [FormulaTermEntity] = []

    public var deck: SlideDeckEntity?

    public var slideType: SlideType {
        get { SlideType(rawValue: slideTypeRaw) ?? .keyConcept }
        set { slideTypeRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        slideIndex: Int,
        slideIdTag: String = "BIO-03-A",
        slideType: SlideType = .keyConcept,
        title: String,
        summary: String,
        bulletPoints: [String] = [],
        apExamTrap: String? = nil,
        equationString: String? = nil
    ) {
        self.id = id
        self.slideIndex = slideIndex
        self.slideIdTag = slideIdTag
        self.slideTypeRaw = slideType.rawValue
        self.title = title
        self.summary = summary
        self.bulletPoints = bulletPoints
        self.apExamTrap = apExamTrap
        self.equationString = equationString
    }
}

// MARK: - SwiftData Slide Deck Entity
@Model
public final class SlideDeckEntity {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var course: String
    public var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \SlideEntity.deck)
    public var slides: [SlideEntity] = []

    public var document: DocumentEntity?

    public init(
        id: UUID = UUID(),
        title: String,
        course: String = "AP Biology",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.course = course
        self.createdAt = createdAt
    }
}
