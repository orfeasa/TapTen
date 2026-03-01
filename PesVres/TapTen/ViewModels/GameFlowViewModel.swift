import Foundation
import Observation

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
    }

    private let settings: GameSettings
    private let enabledCategoryNames: Set<String>
    private let randomSassyCommentProvider: ([String]) -> String

    private var engine: GameEngine?
    private var hasCommittedActiveRound = false

    private(set) var phase: Phase = .error("Unable to start game.")
    private(set) var hostRoundViewModel: HostRoundViewModel?
    private(set) var latestRoundSummary: RoundSummary?
    private(set) var teamAScore = 0
    private(set) var teamBScore = 0

    init(
        settings: GameSettings,
        enabledCategoryNames: Set<String>,
        questionPackLoader: QuestionPackLoader = QuestionPackLoader(),
        randomSassyCommentProvider: @escaping ([String]) -> String = { comments in
            comments.randomElement() ?? "Confetti machine malfunctioned. You still get a clap."
        }
    ) {
        self.settings = settings
        self.enabledCategoryNames = enabledCategoryNames
        self.randomSassyCommentProvider = randomSassyCommentProvider

        do {
            let packs = try questionPackLoader.loadAllPacks()
            try configureEngine(questionPacks: packs)
        } catch {
            setError(error.localizedDescription)
        }
    }

    init(
        settings: GameSettings,
        enabledCategoryNames: Set<String>,
        questionPacks: [QuestionPack],
        randomIndexProvider: @escaping (Int) -> Int = { Int.random(in: 0..<$0) },
        randomSassyCommentProvider: @escaping ([String]) -> String = { comments in
            comments.randomElement() ?? "Confetti machine malfunctioned. You still get a clap."
        }
    ) {
        self.settings = settings
        self.enabledCategoryNames = enabledCategoryNames
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

    var totalRoundCount: Int {
        settings.numberOfRounds
    }

    var roundProgressText: String {
        guard let roundNumber = currentRound?.roundNumber else {
            return "Final Results"
        }
        return "Round \(roundNumber) of \(settings.numberOfRounds)"
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
        if completedAfterCurrentSummary >= settings.numberOfRounds {
            return "See Final Results"
        }

        return "Pass Phone"
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
            roundDurationSeconds: settings.roundDurationSeconds
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
            roundNumber: currentRound.roundNumber,
            prompt: currentRound.question.prompt,
            sourceURL: currentRound.question.sourceURL,
            sassyComment: makeRoundSassyComment(
                revealedAnswers: revealedAnswers,
                totalAnswers: totalAnswers
            ),
            answeringTeamName: answeringTeamName,
            pointsAwarded: pointsAwarded,
            revealedAnswers: revealedAnswers,
            totalAnswers: totalAnswers
        )
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

    private func configureEngine(
        questionPacks: [QuestionPack],
        randomIndexProvider: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }
    ) throws {
        engine = try GameEngine(
            settings: settings,
            questionPacks: questionPacks,
            enabledCategories: enabledCategoryNames,
            randomIndexProvider: randomIndexProvider
        )

        phase = .passDevice
    }

    private func setError(_ message: String) {
        phase = .error(message)
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
                "That round was mostly vibes and very few answers.",
                "If guessing was cardio, you'd still be at warm-up pace.",
                "Bold strategy: reveal almost nothing and call it mystery."
            ]
        case ..<0.45:
            return [
                "Not a disaster, but definitely a character-building performance.",
                "You found a few answers and left the rest for archaeology.",
                "Half-cooked effort, served with confidence."
            ]
        case ..<0.7:
            return [
                "Solid showing. Mildly smug behavior is now permitted.",
                "You did well enough to brag, but keep it tasteful.",
                "Respectable work. Nobody needs to pretend this was luck."
            ]
        case ..<0.9:
            return [
                "Now that was sharp. The other team may request therapy.",
                "Excellent run. You made this look suspiciously rehearsed.",
                "Strong performance. Someone clearly came prepared to win."
            ]
        default:
            return [
                "Absolute demolition. Please leave some points for society.",
                "Nearly perfect. Somewhere a trivia host just got nervous.",
                "That was ruthless. Sportsmanship survives, barely."
            ]
        }
    }
}
