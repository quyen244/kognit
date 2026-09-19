import Foundation
import SwiftData

public struct SampleDataService {
    @MainActor
    public static func populateInitialDataIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<DocumentEntity>()
        let count = (try? context.fetchCount(descriptor)) ?? 0
        if count > 0 { return }

        // 1. Create Document 1: Cellular Respiration
        let doc1 = DocumentEntity(
            filename: "Cellular_Respiration.pdf",
            fileType: "pdf",
            rawText: "AP Biology Unit 3: Cellular Respiration and Photosynthesis...",
            course: "AP Biology",
            pageCount: 18,
            createdAt: Date().addingTimeInterval(-86400 * 2),
            isProcessed: true
        )
        context.insert(doc1)

        // Slide Deck
        let deck1 = SlideDeckEntity(title: "Cellular Respiration Master Deck", course: "AP Biology")
        deck1.document = doc1
        context.insert(deck1)

        let slide1 = SlideEntity(
            slideIndex: 0,
            slideIdTag: "BIO-03-A",
            slideType: .keyConcept,
            title: "Glycolysis: Cytoplasmic Cleavage",
            summary: "Glycolysis is the anaerobic breakdown of one 6-carbon glucose molecule into two 3-carbon pyruvate molecules in the cell cytosol.",
            bulletPoints: [
                "Energy Investment: Consumes 2 ATP to phosphorylate glucose into fructose-1,6-bisphosphate.",
                "Energy Harvest: Yields 4 ATP + 2 NADH by substrate-level phosphorylation (Net: +2 ATP)."
            ],
            apExamTrap: "Glycolysis requires no oxygen and occurs in the cytosol, NOT inside the mitochondria!"
        )
        slide1.deck = deck1
        context.insert(slide1)

        let slide2 = SlideEntity(
            slideIndex: 1,
            slideIdTag: "BIO-03-B",
            slideType: .formulaHighlight,
            title: "Aerobic Respiration Overall Equation",
            summary: "The stoichiometric oxidation of glucose coupled to oxygen reduction to generate ATP across three distinct metabolic stages.",
            bulletPoints: [
                "Glycolysis: Cytosol (Net 2 ATP + 2 NADH)",
                "Krebs Cycle: Mitochondrial Matrix (2 ATP + 6 NADH + 2 FADH2)",
                "Oxidative Phosphorylation: Inner Membrane Cristae (~26-28 ATP)"
            ],
            apExamTrap: "Actual in vivo yield is 30-32 ATP, not 36-38, due to proton leak and NADH shuttle transport costs.",
            equationString: "C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O + 30-32 ATP"
        )
        slide2.deck = deck1
        context.insert(slide2)

        let term1 = FormulaTermEntity(
            symbol: "C₆H₁₂O₆",
            name: "Glucose",
            explanation: "Fully oxidized into 6 CO₂ molecules during pyruvate oxidation & Krebs cycle.",
            colorHex: "#3B82F6"
        )
        term1.slide = slide2
        context.insert(term1)

        let term2 = FormulaTermEntity(
            symbol: "6 O₂",
            name: "Terminal e⁻",
            explanation: "Acts as terminal electron acceptor at Complex IV, combining with protons to form H₂O.",
            colorHex: "#8B5CF6"
        )
        term2.slide = slide2
        context.insert(term2)

        let term3 = FormulaTermEntity(
            symbol: "32 ATP",
            name: "Net Yield",
            explanation: "Generated primarily via chemiosmosis driven by ATP synthase in oxidative phosphorylation.",
            colorHex: "#10B981"
        )
        term3.slide = slide2
        context.insert(term3)

        let slide3 = SlideEntity(
            slideIndex: 2,
            slideIdTag: "BIO-03-C",
            slideType: .digestibleSummary,
            title: "Redox Mnemonic: OIL RIG",
            summary: "A memory framework for tracking high-energy electron transfers in bioenergetics pathways.",
            bulletPoints: [
                "OIL: Oxidation Is Loss of electrons or hydrogen atoms.",
                "RIG: Reduction Is Gain of electrons or hydrogen atoms.",
                "In respiration: Glucose is oxidized to CO₂; Oxygen is reduced to H₂O."
            ],
            apExamTrap: "Dehydrogenase enzymes remove pairs of hydrogen atoms (2 electrons + 1 proton transferred to NAD+)."
        )
        slide3.deck = deck1
        context.insert(slide3)

        // Flashcards
        let cardsData = [
            (
                "What is the net ATP yield produced per glucose molecule through glycolysis alone?",
                "Net 2 ATP (and 2 NADH)",
                "Glycolysis consumes 2 ATP during phosphorylation and generates 4 ATP by substrate-level phosphorylation, yielding a net of 2 ATP.",
                "(Consider energy investment vs payoff phases)",
                1
            ),
            (
                "Where in the eukaryotic cell does the Citric Acid (Krebs) cycle take place?",
                "Mitochondrial Matrix",
                "Unlike glycolysis (cytosol) and oxidative phosphorylation (inner mitochondrial membrane), Krebs cycle enzymes are soluble in the matrix.",
                "(Think about the mitochondrial sub-compartments)",
                2
            ),
            (
                "What is the primary function of oxygen in cellular aerobic respiration?",
                "Terminal Electron Acceptor",
                "Oxygen has high electronegativity, pulling electrons through Complexes I-IV, combining with protons to form H2O and maintaining the proton gradient.",
                "(End of the electron transport chain)",
                3
            ),
            (
                "Which enzyme is responsible for synthesizing ATP using the proton motive force?",
                "ATP Synthase",
                "Protons flow down their electrochemical gradient from the intermembrane space through ATP synthase into the matrix, driving ADP + Pi -> ATP.",
                "(Embedded in the inner mitochondrial membrane cristae)",
                4
            ),
            (
                "In the light reactions of photosynthesis, where do replacement electrons for Photosystem II originate?",
                "Photolysis of Water (H₂O)",
                "An enzyme on the lumen side of PSII splits H2O into 2 H+, 2 e-, and 1/2 O2, releasing oxygen gas as a biological byproduct.",
                "(Photolysis reaction)",
                5
            )
        ]

        for (q, a, exp, hint, idx) in cardsData {
            let card = FlashcardEntity(
                front: q,
                back: a,
                explanation: exp,
                hint: hint,
                unitTag: "AP Bio Unit 3",
                cardIndex: idx,
                stability: 1.5,
                difficulty: 4.8,
                repetitions: 1,
                state: .learning,
                nextReviewDate: Date().addingTimeInterval(3600 * 4) // due soon
            )
            card.document = doc1
            context.insert(card)
        }

        // Mock Exam
        let exam = ExamEntity(
            title: "AP Biology Unit 3 Diagnostic Mock Exam",
            course: "AP Biology",
            standard: .ap,
            timeLimitSeconds: 15 * 60 // 15 minutes
        )
        exam.document = doc1
        context.insert(exam)

        // MCQ 1
        let mcq1 = ExamQuestionEntity(
            questionIndex: 0,
            questionType: .mcq,
            prompt: "What is the primary terminal electron acceptor in the light-dependent reactions of photosynthesis?",
            stimulusText: "During non-cyclic photophosphorylation, photons excite electrons in Photosystem II and I.",
            stimulusTag: "Stimulus-Based",
            maxPoints: 1
        )
        mcq1.exam = exam
        context.insert(mcq1)

        let optA = OptionEntity(
            letter: "A",
            text: "Cytochrome b₆f complex",
            isCorrect: false,
            distractorRationale: "Cytochrome b6f is an intermediate proton pump transferring electrons between PSII and PSI, not the terminal acceptor."
        )
        optA.question = mcq1
        context.insert(optA)

        let optB = OptionEntity(
            letter: "B",
            text: "NADP⁺ (reduced to NADPH)",
            isCorrect: true,
            distractorRationale: "NADP+ reductase transfers electrons to NADP+, reducing it to NADPH for use in the Calvin cycle."
        )
        optB.question = mcq1
        context.insert(optB)

        let optC = OptionEntity(
            letter: "C",
            text: "H₂O (water)",
            isCorrect: false,
            distractorRationale: "H2O is the initial electron donor (photolyzed at PSII), not the electron acceptor."
        )
        optC.question = mcq1
        context.insert(optC)

        let optD = OptionEntity(
            letter: "D",
            text: "CO₂ (carbon dioxide)",
            isCorrect: false,
            distractorRationale: "CO2 is the carbon substrate in the light-independent Calvin cycle, not the light reactions."
        )
        optD.question = mcq1
        context.insert(optD)

        // MCQ 2
        let mcq2 = ExamQuestionEntity(
            questionIndex: 1,
            questionType: .mcq,
            prompt: "Dinitrophenol (DNP) makes the inner mitochondrial membrane permeable to protons. What is the immediate effect of DNP on isolated mitochondria?",
            stimulusText: "A scientist introduces 10mM DNP to an active suspension of mitochondria consuming pyruvate.",
            stimulusTag: "Experimental Stimulus",
            maxPoints: 1
        )
        mcq2.exam = exam
        context.insert(mcq2)

        let opt2A = OptionEntity(
            letter: "A",
            text: "ATP synthesis stops, but oxygen consumption continues",
            isCorrect: true,
            distractorRationale: "DNP uncouples the proton gradient from ATP synthase; electrons still flow to O2 generating heat instead of ATP."
        )
        opt2A.question = mcq2
        context.insert(opt2A)

        let opt2B = OptionEntity(
            letter: "B",
            text: "Both oxygen consumption and ATP synthesis immediately halt",
            isCorrect: false,
            distractorRationale: "Oxygen consumption actually increases because the lack of proton backpressure accelerates electron transport."
        )
        opt2B.question = mcq2
        context.insert(opt2B)

        let opt2C = OptionEntity(
            letter: "C",
            text: "The proton motive force across the inner membrane increases",
            isCorrect: false,
            distractorRationale: "Protons freely leak back into the matrix, destroying the electrochemical gradient."
        )
        opt2C.question = mcq2
        context.insert(opt2C)

        let opt2D = OptionEntity(
            letter: "D",
            text: "Glycolysis in the cytosol is completely inhibited",
            isCorrect: false,
            distractorRationale: "Glycolysis is stimulated by the surge in ADP and AMP levels."
        )
        opt2D.question = mcq2
        context.insert(opt2D)

        // FRQ 1
        let frq = ExamQuestionEntity(
            questionIndex: 2,
            questionType: .frq,
            prompt: "An inhibitor blocks ATP synthase in isolated mitochondria. Predict and justify the effect on the proton gradient across the inner membrane.",
            stimulusText: "Isolated rat liver mitochondria are supplied with pyruvate, inorganic phosphate, and ADP. Oligomycin is added.",
            stimulusTag: "AP Rubric Scoring",
            maxPoints: 4
        )
        frq.exam = exam
        context.insert(frq)

        let p1 = RubricPointEntity(
            pointNumber: 1,
            criteriaTitle: "Point 1: Prediction",
            requirementDescription: "Predicts that the proton gradient increases or remains at maximum high level."
        )
        p1.question = frq
        context.insert(p1)

        let p2 = RubricPointEntity(
            pointNumber: 2,
            criteriaTitle: "Point 2: Pathway Blockage",
            requirementDescription: "Explains that protons can no longer flow down their electrochemical gradient into the matrix through ATP synthase."
        )
        p2.question = frq
        context.insert(p2)

        let p3 = RubricPointEntity(
            pointNumber: 3,
            criteriaTitle: "Point 3: ETC Mechanism",
            requirementDescription: "Notes that the electron transport chain continues pumping protons until the steep backpressure electrochemical gradient stalls further electron flow."
        )
        p3.question = frq
        context.insert(p3)

        let p4 = RubricPointEntity(
            pointNumber: 4,
            criteriaTitle: "Point 4: System Synthesis",
            requirementDescription: "Concludes that ATP synthesis drops to zero despite abundant substrate availability."
        )
        p4.question = frq
        context.insert(p4)

        // 2. Create User Settings
        let settingsDescriptor = FetchDescriptor<UserSettingsEntity>()
        let settingsCount = (try? context.fetchCount(settingsDescriptor)) ?? 0
        if settingsCount == 0 {
            let userSettings = UserSettingsEntity()
            context.insert(userSettings)
        }

        try? context.save()
    }

    // Helper to generate synthesis result for API client simulation
    public static func makeSampleSynthesisResult(jobId: String) -> IngestionSynthesisResult {
        let slides = [
            SynthesizedSlide(
                slideIndex: 0,
                slideIdTag: "BIO-03-A",
                slideType: .keyConcept,
                title: "Glycolysis: Cytoplasmic Cleavage",
                summary: "Glycolysis is the anaerobic breakdown of one 6-carbon glucose molecule into two 3-carbon pyruvate molecules.",
                bulletPoints: [
                    "Energy Investment: Consumes 2 ATP to phosphorylate glucose.",
                    "Energy Harvest: Yields 4 ATP + 2 NADH (Net: +2 ATP)."
                ],
                apExamTrap: "Glycolysis requires no oxygen and occurs in the cytosol, NOT inside mitochondria!"
            ),
            SynthesizedSlide(
                slideIndex: 1,
                slideIdTag: "BIO-03-B",
                slideType: .formulaHighlight,
                title: "Aerobic Respiration Overall Equation",
                summary: "Complete stoichiometric oxidation of glucose coupled to oxygen reduction to generate ATP.",
                bulletPoints: [
                    "Glucose oxidized to CO2",
                    "Oxygen reduced to H2O",
                    "30-32 net ATP produced"
                ],
                apExamTrap: "Actual yield is 30-32 ATP, not 36-38, due to proton leak.",
                equationString: "C₆H₁₂O₆ + 6O₂ → 6CO₂ + 6H₂O + 30-32 ATP",
                formulaTerms: [
                    ("C₆H₁₂O₆", "Glucose", "Fully oxidized to 6 CO2 molecules during Krebs.", "#3B82F6"),
                    ("6 O₂", "Terminal e⁻", "Terminal electron acceptor, forming 6 H2O.", "#8B5CF6"),
                    ("32 ATP", "Net Yield", "Net via oxidative phosphorylation + chemiosmosis.", "#10B981")
                ]
            ),
            SynthesizedSlide(
                slideIndex: 2,
                slideIdTag: "BIO-03-C",
                slideType: .digestibleSummary,
                title: "Redox Mnemonic: OIL RIG",
                summary: "Memory device for tracking electron transfer in energetic pathways.",
                bulletPoints: [
                    "OIL: Oxidation Is Loss of electrons or Hydrogen.",
                    "RIG: Reduction Is Gain of electrons or Hydrogen."
                ],
                apExamTrap: "Glucose is oxidized to CO2, oxygen is reduced to water."
            )
        ]

        let flashcards = [
            SynthesizedFlashcard(
                front: "What is the net ATP yield produced per glucose molecule through glycolysis alone?",
                back: "Net 2 ATP (and 2 NADH)",
                explanation: "Glycolysis consumes 2 ATP and generates 4 ATP by substrate-level phosphorylation, yielding a net of 2 ATP.",
                hint: "(Consider energy investment vs payoff phases)",
                unitTag: "AP Bio Unit 3"
            ),
            SynthesizedFlashcard(
                front: "Where in the eukaryotic cell does the Citric Acid (Krebs) cycle take place?",
                back: "Mitochondrial Matrix",
                explanation: "Unlike glycolysis (cytosol) and oxidative phosphorylation (cristae), Krebs cycle enzymes are soluble in the matrix.",
                hint: "(Think about mitochondrial compartments)",
                unitTag: "AP Bio Unit 3"
            ),
            SynthesizedFlashcard(
                front: "What is the primary function of oxygen in cellular aerobic respiration?",
                back: "Terminal Electron Acceptor",
                explanation: "Oxygen has high electronegativity, pulling electrons through the ETC and forming H2O.",
                hint: "(End of the electron transport chain)",
                unitTag: "AP Bio Unit 3"
            ),
            SynthesizedFlashcard(
                front: "Which enzyme is responsible for synthesizing ATP using the proton motive force?",
                back: "ATP Synthase",
                explanation: "Protons flow down their electrochemical gradient from the intermembrane space through ATP synthase into the matrix.",
                hint: "(Embedded in the cristae)",
                unitTag: "AP Bio Unit 3"
            ),
            SynthesizedFlashcard(
                front: "In the light reactions of photosynthesis, where do replacement electrons for Photosystem II originate?",
                back: "Photolysis of Water (H₂O)",
                explanation: "An enzyme on the lumen side of PSII splits H2O into 2 H+, 2 e-, and 1/2 O2.",
                hint: "(Photolysis reaction)",
                unitTag: "AP Bio Unit 3"
            )
        ]

        let examQuestions = [
            SynthesizedExamQuestion(
                questionIndex: 0,
                questionType: .mcq,
                prompt: "What is the primary terminal electron acceptor in the light-dependent reactions of photosynthesis?",
                stimulusText: "During non-cyclic photophosphorylation, photons excite electrons in Photosystem II and I.",
                maxPoints: 1,
                options: [
                    ("A", "Cytochrome b₆f complex", false, "Cytochrome b6f is an intermediate proton pump, not the terminal electron acceptor."),
                    ("B", "NADP⁺ (reduced to NADPH)", true, "NADP+ reductase transfers electrons to NADP+, reducing it to NADPH for the Calvin cycle."),
                    ("C", "H₂O (water)", false, "H2O is the initial electron donor (photolyzed), not the electron acceptor."),
                    ("D", "CO₂ (carbon dioxide)", false, "CO2 is the carbon substrate in the light-independent Calvin cycle, not the light reactions.")
                ]
            ),
            SynthesizedExamQuestion(
                questionIndex: 1,
                questionType: .frq,
                prompt: "An inhibitor blocks ATP synthase in isolated mitochondria. Predict and justify the effect on the proton gradient across the inner membrane.",
                stimulusText: "Isolated rat liver mitochondria are supplied with pyruvate and ADP.",
                maxPoints: 4,
                rubricPoints: [
                    (1, "Point 1: Prediction", "Predicts proton gradient increases or remains high."),
                    (2, "Point 2: Pathway Blockage", "Explains protons can no longer flow down gradient into matrix."),
                    (3, "Point 3: ETC Mechanism", "Notes ETC continues pumping protons until backpressure stalls it."),
                    (4, "Point 4: Synthesis", "Relates to cessation of ATP synthesis.")
                ]
            )
        ]

        return IngestionSynthesisResult(
            jobId: jobId,
            documentTitle: "Cellular_Respiration.pdf",
            slides: slides,
            flashcards: flashcards,
            examQuestions: examQuestions
        )
    }
}
