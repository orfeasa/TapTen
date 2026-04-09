import Foundation
import Observation
#if DEBUG
import OSLog
#endif

@Observable
final class GameFlowViewModel {
    enum Phase: Equatable {
        case passDevice
        case questionPreview
        case hostRound
        case roundSummary
        case finalResults
        case error(String)
    }

    struct RoundSummary: Equatable {
        let roundNumber: Int
        let prompt: String
        let sourceURL: URL
        let sassyComment: String
        let answeringTeamName: String
        let pointsAwarded: Int
        let revealedAnswers: Int
        let totalAnswers: Int
        let answers: [AnswerOption]
        let revealedAnswerIndices: Set<Int>
        let feedbackContext: QuestionFeedbackContext
    }

    private let settings: GameSettings
    private let enabledCategoryNames: Set<String>
    private let enabledDifficultyTiers: Set<QuestionDifficulty>
    private let soundsEnabled: Bool
    private let monetizationTelemetryStore: MonetizationTelemetryStore
    private let questionCalibrationTelemetryStore: QuestionCalibrationTelemetryStore
    private let randomSassyCommentProvider: ([String]) -> String
    private var questionPacks: [QuestionPack] = []
    private var randomIndexProvider: (Int) -> Int = { Int.random(in: 0..<$0) }

    private var engine: GameEngine?
    private var hasCommittedActiveRound = false

    private(set) var phase: Phase = .error("Unable to start game.")
    private(set) var hostRoundViewModel: HostRoundViewModel?
    private(set) var latestRoundSummary: RoundSummary?
    private(set) var teamAScore = 0
    private(set) var teamBScore = 0
#if DEBUG
    private(set) var debugRoundTelemetry: [DebugRoundTelemetry] = []
#endif

    init(
        settings: GameSettings,
        enabledCategoryNames: Set<String>,
        enabledDifficultyTiers: Set<QuestionDifficulty> = Set(QuestionDifficulty.allCases),
        soundsEnabled: Bool = true,
        questionPackLibrary: QuestionPackLibrary = QuestionPackLibrary(),
        entitlementStore: QuestionPackEntitlementStore = .shared,
        monetizationTelemetryStore: MonetizationTelemetryStore = .shared,
        questionCalibrationTelemetryStore: QuestionCalibrationTelemetryStore = .shared,
        randomIndexProvider: @escaping (Int) -> Int = { Int.random(in: 0..<$0) },
        randomSassyCommentProvider: @escaping ([String]) -> String = { comments in
            comments.randomElement() ?? "Confetti machine malfunctioned. You still get a clap."
        }
    ) {
        self.settings = settings
        self.enabledCategoryNames = enabledCategoryNames
        self.enabledDifficultyTiers = enabledDifficultyTiers
        self.soundsEnabled = soundsEnabled
        self.monetizationTelemetryStore = monetizationTelemetryStore
        self.questionCalibrationTelemetryStore = questionCalibrationTelemetryStore
        self.randomIndexProvider = randomIndexProvider
        self.randomSassyCommentProvider = randomSassyCommentProvider

        do {
            let packs = try questionPackLibrary.loadAllPacks()
            let accessiblePacks = entitlementStore.accessiblePacks(from: packs)
            questionPacks = accessiblePacks
            try configureEngine(questionPacks: accessiblePacks, randomIndexProvider: randomIndexProvider)
            monetizationTelemetryStore.recordFirstGameStartedIfNeeded()
        } catch {
            setError(error.localizedDescription)
        }
    }

    init(
        settings: GameSettings,
        enabledCategoryNames: Set<String>,
        enabledDifficultyTiers: Set<QuestionDifficulty> = Set(QuestionDifficulty.allCases),
        soundsEnabled: Bool = true,
        questionPacks: [QuestionPack],
        monetizationTelemetryStore: MonetizationTelemetryStore = .shared,
        questionCalibrationTelemetryStore: QuestionCalibrationTelemetryStore = .shared,
        randomIndexProvider: @escaping (Int) -> Int = { Int.random(in: 0..<$0) },
        randomSassyCommentProvider: @escaping ([String]) -> String = { comments in
            comments.randomElement() ?? "Confetti machine malfunctioned. You still get a clap."
        }
    ) {
        self.settings = settings
        self.enabledCategoryNames = enabledCategoryNames
        self.enabledDifficultyTiers = enabledDifficultyTiers
        self.soundsEnabled = soundsEnabled
        self.monetizationTelemetryStore = monetizationTelemetryStore
        self.questionCalibrationTelemetryStore = questionCalibrationTelemetryStore
        self.questionPacks = questionPacks
        self.randomIndexProvider = randomIndexProvider
        self.randomSassyCommentProvider = randomSassyCommentProvider

        do {
            try configureEngine(
                questionPacks: questionPacks,
                randomIndexProvider: randomIndexProvider
            )
            monetizationTelemetryStore.recordFirstGameStartedIfNeeded()
        } catch {
            setError(error.localizedDescription)
        }
    }

    var currentRound: ActiveGameRound? {
        engine?.currentRound
    }

    var roundsPerTeamCount: Int {
        settings.numberOfRounds
    }

    var roundDurationSeconds: Int {
        settings.roundDurationSeconds
    }

    var roundProgressText: String {
        guard let currentRound else {
            return "Final Results"
        }
        return "Round \(teamRoundNumber(for: currentRound)) of \(settings.numberOfRounds)"
    }

    var teamAName: String {
        settings.teamAName
    }

    var teamBName: String {
        settings.teamBName
    }

    var answeringTeamName: String {
        guard let currentRound, let engine else {
            return ""
        }
        return engine.teamName(for: currentRound.answeringTeam)
    }

    var hostingTeamName: String {
        guard let currentRound, let engine else {
            return ""
        }
        return engine.teamName(for: currentRound.answeringTeam.next)
    }

    var currentQuestionFeedbackContext: QuestionFeedbackContext? {
        guard let currentRound,
              currentPack?.origin == .bundled else {
            return nil
        }

        return feedbackContext(for: currentRound.question)
    }

    var currentQuestionShowsReviewUtilities: Bool {
        currentPack?.origin == .bundled
    }

    var currentQuestionPrompt: String {
        currentRound?.question.prompt ?? ""
    }

    var summaryContinueButtonTitle: String {
        guard let engine else {
            return "Continue"
        }

        let completedAfterCurrentSummary = engine.completedRounds + 1
        if completedAfterCurrentSummary >= engine.totalRoundCount {
            return "Continue to Final Results"
        }

        return "Next Round"
    }

    var winnerName: String? {
        if teamAScore == teamBScore {
            return nil
        }

        return teamAScore > teamBScore ? settings.teamAName : settings.teamBName
    }

    var winnerTitle: String {
        if let winnerName {
            return "\(winnerName.uppercased()) WINS!"
        }

        return "IT'S A TIE!"
    }

    func showQuestionPreview() {
        guard phase == .passDevice, currentRound != nil else {
            return
        }

        phase = .questionPreview
    }

    func startRound() {
        guard phase == .questionPreview, let currentRound else {
            return
        }

        hasCommittedActiveRound = false
        latestRoundSummary = nil

        hostRoundViewModel = HostRoundViewModel(
            question: currentRound.question,
            roundDurationSeconds: settings.roundDurationSeconds,
            soundsEnabled: soundsEnabled
        )
        phase = .hostRound
    }

    func finalizeActiveRoundIfNeeded() {
        guard phase == .hostRound else {
            return
        }

        guard !hasCommittedActiveRound else {
            return
        }

        guard let currentRound, let hostRoundViewModel else {
            setError("Active round data is missing.")
            return
        }

        hasCommittedActiveRound = true

        let pointsAwarded = hostRoundViewModel.pointsAwarded
        let revealedAnswers = hostRoundViewModel.revealedAnswerIndices.count
        let totalAnswers = currentRound.question.answers.count
        let feedbackContext = feedbackContext(for: currentRound.question)
        let finishReason = hostRoundViewModel.finishReason
        let remainingTimeAtFinish = hostRoundViewModel.timeRemainingAtFinish ?? hostRoundViewModel.remainingTime

        if currentRound.answeringTeam == .teamA {
            teamAScore += pointsAwarded
        } else {
            teamBScore += pointsAwarded
        }

        latestRoundSummary = RoundSummary(
            roundNumber: teamRoundNumber(for: currentRound),
            prompt: currentRound.question.prompt,
            sourceURL: currentRound.question.sourceURL,
            sassyComment: makeRoundSassyComment(
                revealedAnswers: revealedAnswers,
                totalAnswers: totalAnswers
            ),
            answeringTeamName: answeringTeamName,
            pointsAwarded: pointsAwarded,
            revealedAnswers: revealedAnswers,
            totalAnswers: totalAnswers,
            answers: currentRound.question.answers,
            revealedAnswerIndices: hostRoundViewModel.revealedAnswerIndices,
            feedbackContext: feedbackContext
        )
        questionCalibrationTelemetryStore.recordRoundOutcome(
            context: feedbackContext,
            roundDurationSeconds: settings.roundDurationSeconds,
            finishReason: finishReason,
            revealedAnswerIndices: hostRoundViewModel.revealedAnswerIndices,
            totalAnswers: totalAnswers,
            pointsAwarded: pointsAwarded,
            remainingTimeAtFinish: remainingTimeAtFinish,
            timeToFirstReveal: hostRoundViewModel.timeToFirstReveal
        )
        Task {
            await QuestionCalibrationSubmissionService.shared.submitPendingEventsIfPossible()
        }
#if DEBUG
        let telemetry = DebugRoundTelemetry(
            roundNumber: teamRoundNumber(for: currentRound),
            questionID: currentRound.question.id,
            category: currentRound.question.category,
            difficultyTier: currentRound.question.difficultyTier,
            answeringTeamName: answeringTeamName,
            revealedAnswers: revealedAnswers,
            revealedAnswerIndices: hostRoundViewModel.revealedAnswerIndices.sorted(),
            totalAnswers: totalAnswers,
            pointsAwarded: pointsAwarded,
            finishReason: finishReason,
            remainingTimeAtFinish: remainingTimeAtFinish,
            timeToFirstReveal: hostRoundViewModel.timeToFirstReveal
        )
        debugRoundTelemetry.append(telemetry)
        let finishReasonLabel = telemetry.finishReason?.rawValue ?? "unknown"
        let firstRevealLabel = telemetry.timeToFirstReveal.map {
            String(format: "%.1f", $0)
        } ?? "-"
        Self.telemetryLogger.debug(
            "Round \(telemetry.roundNumber) | question: \(telemetry.questionID, privacy: .public) | category: \(telemetry.category, privacy: .public) | tier: \(telemetry.difficultyTier.rawValue, privacy: .public) | team: \(telemetry.answeringTeamName, privacy: .public) | finish: \(finishReasonLabel, privacy: .public) | revealed: \(telemetry.revealedAnswers)/\(telemetry.totalAnswers) | points: \(telemetry.pointsAwarded) | firstReveal: \(firstRevealLabel, privacy: .public)s | remaining: \(telemetry.remainingTimeAtFinish, format: .fixed(precision: 1))s"
        )
#endif
        phase = .roundSummary
    }

    func continueAfterRoundSummary() {
        guard phase == .roundSummary else {
            return
        }

        guard var engine else {
            setError("Game engine is unavailable.")
            return
        }

        do {
            try engine.completeRound()
        } catch {
            setError(error.localizedDescription)
            return
        }

        self.engine = engine
        hostRoundViewModel = nil

        if engine.isGameOver {
            monetizationTelemetryStore.recordFirstGameCompletedIfNeeded()
            phase = .finalResults
        } else {
            phase = .passDevice
        }
    }

    func playAgain() {
        guard phase == .finalResults else {
            return
        }

        do {
            try configureEngine(
                questionPacks: questionPacks,
                randomIndexProvider: randomIndexProvider
            )
            teamAScore = 0
            teamBScore = 0
            latestRoundSummary = nil
            hostRoundViewModel = nil
            hasCommittedActiveRound = false
#if DEBUG
            debugRoundTelemetry.removeAll()
#endif
        } catch {
            setError(error.localizedDescription)
        }
    }

    private func configureEngine(
        questionPacks: [QuestionPack],
        randomIndexProvider: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }
    ) throws {
        engine = try GameEngine(
            settings: settings,
            questionPacks: questionPacks,
            enabledCategories: enabledCategoryNames,
            enabledDifficulties: enabledDifficultyTiers,
            randomIndexProvider: randomIndexProvider
        )

        phase = .passDevice
    }

    private func setError(_ message: String) {
        phase = .error(message)
    }

    private func feedbackContext(for question: Question) -> QuestionFeedbackContext {
        let containingPack = containingPack(for: question)

        return QuestionFeedbackContext(
            packID: containingPack?.id,
            packTitle: containingPack?.title,
            packVersion: containingPack?.packVersion,
            questionID: question.id,
            prompt: question.prompt,
            category: question.category,
            difficultyTier: question.difficultyTier,
            validationStyle: question.validationStyle,
            sourceURL: question.sourceURL
        )
    }

    private var currentPack: QuestionPack? {
        guard let currentRound else {
            return nil
        }

        return containingPack(for: currentRound.question)
    }

    private func containingPack(for question: Question) -> QuestionPack? {
        questionPacks.first { pack in
            pack.questions.contains(where: { $0.id == question.id })
        }
    }

    private func makeRoundSassyComment(revealedAnswers: Int, totalAnswers: Int) -> String {
        let clampedTotalAnswers = max(totalAnswers, 1)
        let revealedRatio = Double(revealedAnswers) / Double(clampedTotalAnswers)
        let comments = comments(for: revealedRatio)
        return randomSassyCommentProvider(comments)
    }

    private func comments(for revealedRatio: Double) -> [String] {
        switch revealedRatio {
        case ..<0.2:
            return [
                "Bold noise, light damage.",
                "Big swing. Tiny scoreboard.",
                "More chaos than points."
            ]
        case ..<0.45:
            return [
                "Solid try. Not quite ruthless.",
                "Good pace, patchy finish.",
                "Some hits, some hopeful shouting."
            ]
        case ..<0.7:
            return [
                "Strong round. Clean work.",
                "Composed and quick.",
                "Nice control under pressure."
            ]
        case ..<0.9:
            return [
                "That was sharp.",
                "Clinical round.",
                "You made that look easy."
            ]
        default:
            return [
                "Absolute clinic.",
                "Elite round. No notes.",
                "That was borderline unfair."
            ]
        }
    }

    private func teamRoundNumber(for round: ActiveGameRound) -> Int {
        switch round.answeringTeam {
        case .teamA:
            return (round.roundNumber + 1) / 2
        case .teamB:
            return round.roundNumber / 2
        }
    }

#if DEBUG
    private static let telemetryLogger = Logger(
        subsystem: "TapTen",
        category: "GameplayTelemetry"
    )
#endif
}

#if DEBUG
struct DebugRoundTelemetry: Equatable {
    let roundNumber: Int
    let questionID: String
    let category: String
    let difficultyTier: QuestionDifficulty
    let answeringTeamName: String
    let revealedAnswers: Int
    let revealedAnswerIndices: [Int]
    let totalAnswers: Int
    let pointsAwarded: Int
    let finishReason: HostRoundFinishReason?
    let remainingTimeAtFinish: TimeInterval
    let timeToFirstReveal: TimeInterval?
}
#endif
