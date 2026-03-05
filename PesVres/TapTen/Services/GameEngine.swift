import Foundation

enum GameEngineError: LocalizedError {
    case invalidRoundCount(Int)
    case noQuestionsForEnabledCategories
    case insufficientQuestionsForSession(required: Int, available: Int)
    case noActiveRound
    case invalidRandomIndex(candidateCount: Int, index: Int)

    var errorDescription: String? {
        switch self {
        case .invalidRoundCount(let count):
            return "Rounds per team must be greater than zero. Received \(count)."
        case .noQuestionsForEnabledCategories:
            return "No questions matched the enabled filters."
        case .insufficientQuestionsForSession(let required, let available):
            return "Not enough unique questions for this session. Required \(required), available \(available)."
        case .noActiveRound:
            return "Cannot advance because there is no active round."
        case .invalidRandomIndex(let candidateCount, let index):
            return "Random index \(index) is out of bounds for \(candidateCount) candidates."
        }
    }
}

enum TeamTurn: String, Equatable, Sendable {
    case teamA
    case teamB

    var next: TeamTurn {
        switch self {
        case .teamA:
            return .teamB
        case .teamB:
            return .teamA
        }
    }
}

struct ActiveGameRound: Equatable, Sendable {
    let roundNumber: Int
    let answeringTeam: TeamTurn
    let question: Question
}

struct GameEngine {
    private let settings: GameSettings
    private let questionPool: [Question]
    private let randomIndexProvider: (Int) -> Int

    private(set) var completedRounds = 0
    private(set) var currentRound: ActiveGameRound?
    private(set) var nextTeamTurn: TeamTurn = .teamA
    private var usedQuestionIDs: Set<String> = []

    var totalRoundCount: Int {
        settings.numberOfRounds * 2
    }

    var isGameOver: Bool {
        completedRounds >= totalRoundCount
    }

    var roundsRemaining: Int {
        max(totalRoundCount - completedRounds, 0)
    }

    init(
        settings: GameSettings,
        questionPacks: [QuestionPack],
        enabledCategories: Set<String>,
        enabledDifficulties: Set<QuestionDifficulty> = Set(QuestionDifficulty.allCases),
        randomIndexProvider: @escaping (Int) -> Int = { Int.random(in: 0..<$0) }
    ) throws {
        guard settings.numberOfRounds > 0 else {
            throw GameEngineError.invalidRoundCount(settings.numberOfRounds)
        }
        let totalRoundsForSession = settings.numberOfRounds * 2

        let normalizedEnabledCategories = Set(
            enabledCategories
                .map(\.normalizedCategoryKey)
                .filter { !$0.isEmpty }
        )
        let activeDifficultyFilters = enabledDifficulties.isEmpty
            ? Set(QuestionDifficulty.allCases)
            : enabledDifficulties

        let allQuestions = questionPacks.flatMap(\.questions)
        let filteredQuestions = allQuestions.filter {
            normalizedEnabledCategories.contains($0.category.normalizedCategoryKey)
            && activeDifficultyFilters.contains($0.difficultyTier)
        }

        guard !filteredQuestions.isEmpty else {
            throw GameEngineError.noQuestionsForEnabledCategories
        }

        // Deduplicate by ID so "no repeat in a session" is guaranteed.
        var uniqueQuestionsByID: [String: Question] = [:]
        for question in filteredQuestions where uniqueQuestionsByID[question.id] == nil {
            uniqueQuestionsByID[question.id] = question
        }
        let uniqueQuestions = uniqueQuestionsByID.values.sorted { $0.id < $1.id }

        guard uniqueQuestions.count >= totalRoundsForSession else {
            throw GameEngineError.insufficientQuestionsForSession(
                required: totalRoundsForSession,
                available: uniqueQuestions.count
            )
        }

        self.settings = settings
        self.questionPool = uniqueQuestions
        self.randomIndexProvider = randomIndexProvider
        self.currentRound = nil

        self.currentRound = try makeRound(roundNumber: 1, teamTurn: .teamA)
    }

    mutating func completeRound() throws {
        guard currentRound != nil else {
            throw GameEngineError.noActiveRound
        }

        completedRounds += 1

        if isGameOver {
            currentRound = nil
            return
        }

        nextTeamTurn = nextTeamTurn.next
        currentRound = try makeRound(roundNumber: completedRounds + 1, teamTurn: nextTeamTurn)
    }

    func teamName(for turn: TeamTurn) -> String {
        switch turn {
        case .teamA:
            return settings.teamAName
        case .teamB:
            return settings.teamBName
        }
    }

    private mutating func makeRound(roundNumber: Int, teamTurn: TeamTurn) throws -> ActiveGameRound {
        let unusedQuestions = questionPool.filter { !usedQuestionIDs.contains($0.id) }
        let selectedQuestion = try selectRandomQuestion(from: unusedQuestions)

        usedQuestionIDs.insert(selectedQuestion.id)

        return ActiveGameRound(
            roundNumber: roundNumber,
            answeringTeam: teamTurn,
            question: selectedQuestion
        )
    }

    private func selectRandomQuestion(from candidates: [Question]) throws -> Question {
        let selectedIndex = randomIndexProvider(candidates.count)

        guard candidates.indices.contains(selectedIndex) else {
            throw GameEngineError.invalidRandomIndex(
                candidateCount: candidates.count,
                index: selectedIndex
            )
        }

        return candidates[selectedIndex]
    }
}

private extension String {
    var normalizedCategoryKey: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
