import Foundation
import Observation
#if DEBUG
import OSLog
#endif

@Observable
final class GameFlowViewModel {
    enum Phase: Equatable {
        case passDevice
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
        let feedbackContext: QuestionFeedbackContext
    }

    private let settings: GameSettings
    private let enabledCategoryNames: Set<String>
    private let enabledDifficultyTiers: Set<QuestionDifficulty>
    private let soundsEnabled: Bool
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
        questionPackLoader: QuestionPackLoader = QuestionPackLoader(),
        randomIndexProvider: @escaping (Int) -> Int = { Int.random(in: 0..<$0) },
        randomSassyCommentProvider: @escaping ([String]) -> String = { comments in
            comments.randomElement() ?? "Confetti machine malfunctioned. You still get a clap."
        }
    ) {
        self.settings = settings
        self.enabledCategoryNames = enabledCategoryNames
        self.enabledDifficultyTiers = enabledDifficultyTiers
        self.soundsEnabled = soundsEnabled
        self.randomIndexProvider = randomIndexProvider
        self.randomSassyCommentProvider = randomSassyCommentProvider

        do {
            let packs = try questionPackLoader.loadAllPacks()
            questionPacks = packs
            try configureEngine(questionPacks: packs, randomIndexProvider: randomIndexProvider)
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
        randomIndexProvider: @escaping (Int) -> Int = { Int.random(in: 0..<$0) },
        randomSassyCommentProvider: @escaping ([String]) -> String = { comments in
            comments.randomElement() ?? "Confetti machine malfunctioned. You still get a clap."
        }
    ) {
        self.settings = settings
        self.enabledCategoryNames = enabledCategoryNames
        self.enabledDifficultyTiers = enabledDifficultyTiers
        self.soundsEnabled = soundsEnabled
        self.questionPacks = questionPacks
        self.randomIndexProvider = randomIndexProvider
        self.randomSassyCommentProvider = randomSassyCommentProvider

        do {
            try configureEngine(
                questionPacks: questionPacks,
                randomIndexProvider: randomIndexProvider
            )
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

    func startRound() {
        guard phase == .passDevice, let currentRound else {
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
            feedbackContext: feedbackContext(for: currentRound.question)
        )
#if DEBUG
        let telemetry = DebugRoundTelemetry(
            roundNumber: teamRoundNumber(for: currentRound),
            category: currentRound.question.category,
            answeringTeamName: answeringTeamName,
            revealedAnswers: revealedAnswers,
            totalAnswers: totalAnswers,
            pointsAwarded: pointsAwarded,
            remainingTimeAtSummary: hostRoundViewModel.remainingTime
        )
        debugRoundTelemetry.append(telemetry)
        Self.telemetryLogger.debug(
            "Round \(telemetry.roundNumber) | category: \(telemetry.category, privacy: .public) | team: \(telemetry.answeringTeamName, privacy: .public) | revealed: \(telemetry.revealedAnswers)/\(telemetry.totalAnswers) | points: \(telemetry.pointsAwarded) | remaining: \(telemetry.remainingTimeAtSummary, format: .fixed(precision: 1))s"
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
        let containingPack = questionPacks.first { pack in
            pack.questions.contains(where: { $0.id == question.id })
        }

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
    let category: String
    let answeringTeamName: String
    let revealedAnswers: Int
    let totalAnswers: Int
    let pointsAwarded: Int
    let remainingTimeAtSummary: TimeInterval
}
#endif
