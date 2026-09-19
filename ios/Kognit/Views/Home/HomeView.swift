import SwiftUI
import SwiftData

public struct HomeView: View {
    @Query(sort: \DocumentEntity.createdAt, order: .reverse) private var documents: [DocumentEntity]
    @Query private var userSettingsList: [UserSettingsEntity]

    @Binding var selectedTab: Int
    var onOpenScanner: () -> Void
    var onOpenSlides: () -> Void
    var onOpenCards: () -> Void
    var onOpenExam: () -> Void

    public init(
        selectedTab: Binding<Int>,
        onOpenScanner: @escaping () -> Void = {},
        onOpenSlides: @escaping () -> Void = {},
        onOpenCards: @escaping () -> Void = {},
        onOpenExam: @escaping () -> Void = {}
    ) {
        self._selectedTab = selectedTab
        self.onOpenScanner = onOpenScanner
        self.onOpenSlides = onOpenSlides
        self.onOpenCards = onOpenCards
        self.onOpenExam = onOpenExam
    }

    private var settings: UserSettingsEntity? {
        userSettingsList.first
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // MARK: - Header Greeting & Streak
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 4) {
                                Text("Hey, \(settings?.studentName ?? "Alex")")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                Text("👋")
                                    .font(.system(size: 20))
                            }
                            HStack(spacing: 4) {
                                Text("AP Bio Exam in")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("14 days")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.orange)
                                Text("• Lock in! 🧠")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.purple)
                            }
                        }

                        Spacer()

                        HStack(spacing: 8) {
                            StreakBadge(streakDays: settings?.streakCount ?? 12)

                            // Avatar with vibrant ring
                            ZStack {
                                Circle()
                                    .stroke(
                                        LinearGradient(colors: [.blue, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        lineWidth: 2.5
                                    )
                                    .frame(width: 38, height: 38)

                                Circle()
                                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 32, height: 32)

                                Text("AL")
                                    .font(.system(size: 12, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .padding(.top, 4)

                    // MARK: - Level & XP Gamification Card
                    LevelProgressCard(xp: 1850)

                    // MARK: - Quick Ingestion Callout Banner
                    Button(action: {
                        selectedTab = 1
                    }) {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "#3B82F6"), Color(hex: "#8B5CF6"), Color(hex: "#EC4899")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 48, height: 48)
                                    .shadow(color: .purple.opacity(0.3), radius: 6, x: 0, y: 3)

                                Image(systemName: "sparkles")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 6) {
                                    Text("Ingest Study Material")
                                        .font(.system(size: 14, weight: .bold, design: .rounded))
                                        .foregroundColor(.primary)
                                    KognitBadge("AI Turbo ⚡", color: .purple)
                                }
                                Text("Snap handwritten notes, slides, or textbook pages")
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.12), Color.purple.opacity(0.12), Color.pink.opacity(0.06)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.4)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                    }
                    .bouncyButton()

                    // MARK: - Study Modalities 4-Grid
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("STUDY MODALITIES")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("Tap to level up")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.purple)
                        }

                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                            // 1. Scanner
                            ModalityButton(
                                title: "Scanner",
                                subtitle: "Notes & PDF",
                                icon: "camera.viewfinder",
                                gradient: [.blue, .cyan]
                            ) {
                                selectedTab = 1
                            }

                            // 2. Slide Decks
                            ModalityButton(
                                title: "Slide Decks",
                                subtitle: "12 Concepts",
                                icon: "doc.text.below.ecg.fill",
                                gradient: [.purple, .indigo]
                            ) {
                                selectedTab = 2
                            }

                            // 3. Flashcards
                            ModalityButton(
                                title: "Flashcards",
                                subtitle: "8 Due Today",
                                icon: "rectangle.portrait.on.rectangle.portrait.angled.fill",
                                gradient: [.green, .mint]
                            ) {
                                selectedTab = 3
                            }

                            // 4. Mock Exam
                            ModalityButton(
                                title: "Mock Exam",
                                subtitle: "Timed & FRQ",
                                icon: "stopwatch.fill",
                                gradient: [.orange, .red]
                            ) {
                                selectedTab = 4
                            }
                        }
                    }

                    // MARK: - Mastery & Readiness Gauge
                    MasteryGaugeView(
                        masteryPercentage: settings?.masteryPercentage ?? 78,
                        projectedScore: settings?.projectedScore ?? "4.4 / 5.0",
                        cellEnergyPercentage: settings?.cellEnergyMastery ?? 85,
                        geneticsPercentage: settings?.geneticsMastery ?? 72
                    )

                    // MARK: - Achievements Trophy Bar
                    AchievementBadgeView()

                    // MARK: - Recent Documents List
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("RECENT DOCUMENTS")
                                .font(.system(size: 10, weight: .black, design: .rounded))
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("+ Ingest") {
                                selectedTab = 1
                            }
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.blue)
                        }

                        if documents.isEmpty {
                            Text("No documents ingested yet. Snap your first note!")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .kognitCard()
                        } else {
                            VStack(spacing: 8) {
                                ForEach(documents.prefix(5)) { doc in
                                    RecentDocRow(doc: doc) {
                                        selectedTab = 2
                                    }
                                    .bouncyButton()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("Kognit")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Modality Button Component
private struct ModalityButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 38, height: 38)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(gradient.first ?? .blue)
                }

                Spacer(minLength: 0)
            }
            .padding(10)
            .kognitCard(cornerRadius: 16)
        }
        .bouncyButton()
    }
}

// MARK: - Recent Document Row
private struct RecentDocRow: View {
    let doc: DocumentEntity
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(doc.fileType == "pdf" ? Color.red.opacity(0.15) : Color.indigo.opacity(0.15))
                        .frame(width: 34, height: 34)
                    Image(systemName: doc.fileType == "pdf" ? "doc.richtext.fill" : "camera.fill")
                        .font(.system(size: 14))
                        .foregroundColor(doc.fileType == "pdf" ? .red : .indigo)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.filename)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .foregroundColor(.primary)
                    Text("\(doc.pageCount) pages • \(doc.course)")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                }

                Spacer()

                KognitBadge(doc.isProcessed ? "Ready ⚡" : "Processing", color: doc.isProcessed ? .green : .orange)
            }
            .padding(10)
            .kognitCard(cornerRadius: 14)
        }
    }
}

fileprivate extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
