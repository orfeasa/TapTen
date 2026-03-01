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
        let answeringTeamName: String
        let pointsAwarded: Int
        let revealedAnswers: Int
        let totalAnswers: Int
    }

    private let settings: GameSettings
    private let enabledCategoryNames: Set<String>

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
        questionPackLoader: QuestionPackLoader = QuestionPackLoader()
    ) {
        self.settings = settings
        self.enabledCategoryNames = enabledCategoryNames

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
        randomIndexProvider: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }
    ) {
        self.settings = settings
        self.enabledCategoryNames = enabledCategoryNames

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
        if currentRound.answeringTeam == .teamA {
            teamAScore += pointsAwarded
        } else {
            teamBScore += pointsAwarded
        }

        latestRoundSummary = RoundSummary(
            roundNumber: currentRound.roundNumber,
            prompt: currentRound.question.prompt,
            answeringTeamName: answeringTeamName,
            pointsAwarded: pointsAwarded,
            revealedAnswers: hostRoundViewModel.revealedAnswerIndices.count,
            totalAnswers: currentRound.question.answers.count
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
}
