import Foundation
import Testing
@testable import PesVres

struct GameEngineTests {
    @Test
    func alternatesTurnsBetweenTeamsAcrossRounds() throws {
        let settings = GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 4, roundDurationSeconds: 60)
        let pack = makePack(
            questions: [
                makeQuestion(id: "q1", category: "Factual"),
                makeQuestion(id: "q2", category: "Factual"),
                makeQuestion(id: "q3", category: "Factual"),
                makeQuestion(id: "q4", category: "Factual")
            ]
        )

        var engine = try GameEngine(
            settings: settings,
            questionPacks: [pack],
            enabledCategories: ["Factual"],
            randomIndexProvider: { _ in 0 }
        )

        #expect(engine.currentRound?.answeringTeam == .teamA)
        #expect(engine.currentRound?.roundNumber == 1)

        try engine.completeRound()
        #expect(engine.currentRound?.answeringTeam == .teamB)
        #expect(engine.currentRound?.roundNumber == 2)

        try engine.completeRound()
        #expect(engine.currentRound?.answeringTeam == .teamA)
        #expect(engine.currentRound?.roundNumber == 3)

        try engine.completeRound()
        #expect(engine.currentRound?.answeringTeam == .teamB)
        #expect(engine.currentRound?.roundNumber == 4)
    }

    @Test
    func selectsOnlyFromEnabledCategories() throws {
        let settings = GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 1, roundDurationSeconds: 60)
        let pack = makePack(
            questions: [
                makeQuestion(id: "q1", category: "Factual"),
                makeQuestion(id: "q2", category: "Editorial"),
                makeQuestion(id: "q3", category: "Humorous")
            ]
        )

        let engine = try GameEngine(
            settings: settings,
            questionPacks: [pack],
            enabledCategories: ["Editorial"],
            randomIndexProvider: { _ in 0 }
        )

        #expect(engine.currentRound?.question.category == "Editorial")
    }

    @Test
    func doesNotRepeatQuestionsWithinSession() throws {
        let settings = GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 3, roundDurationSeconds: 60)
        let pack = makePack(
            questions: [
                makeQuestion(id: "q1", category: "Factual"),
                makeQuestion(id: "q2", category: "Factual"),
                makeQuestion(id: "q3", category: "Factual")
            ]
        )

        var engine = try GameEngine(
            settings: settings,
            questionPacks: [pack],
            enabledCategories: ["Factual"],
            randomIndexProvider: { _ in 0 }
        )

        var selectedQuestionIDs: [String] = []
        selectedQuestionIDs.append(engine.currentRound?.question.id ?? "")
        try engine.completeRound()
        selectedQuestionIDs.append(engine.currentRound?.question.id ?? "")
        try engine.completeRound()
        selectedQuestionIDs.append(engine.currentRound?.question.id ?? "")

        #expect(Set(selectedQuestionIDs).count == 3)
    }

    @Test
    func tracksRoundCountAndEndsAfterConfiguredRounds() throws {
        let settings = GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 2, roundDurationSeconds: 60)
        let pack = makePack(
            questions: [
                makeQuestion(id: "q1", category: "Factual"),
                makeQuestion(id: "q2", category: "Factual"),
                makeQuestion(id: "q3", category: "Factual")
            ]
        )

        var engine = try GameEngine(
            settings: settings,
            questionPacks: [pack],
            enabledCategories: ["Factual"],
            randomIndexProvider: { _ in 0 }
        )

        #expect(engine.completedRounds == 0)
        #expect(engine.roundsRemaining == 2)
        #expect(engine.isGameOver == false)

        try engine.completeRound()

        #expect(engine.completedRounds == 1)
        #expect(engine.roundsRemaining == 1)
        #expect(engine.isGameOver == false)
        #expect(engine.currentRound?.roundNumber == 2)

        try engine.completeRound()

        #expect(engine.completedRounds == 2)
        #expect(engine.roundsRemaining == 0)
        #expect(engine.isGameOver == true)
        #expect(engine.currentRound == nil)
    }

    @Test
    func throwsWhenNotEnoughUniqueQuestionsForSession() throws {
        let settings = GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 3, roundDurationSeconds: 60)
        let pack = makePack(
            questions: [
                makeQuestion(id: "q1", category: "Factual"),
                makeQuestion(id: "q1", category: "Factual"),
                makeQuestion(id: "q2", category: "Factual")
            ]
        )

        do {
            _ = try GameEngine(
                settings: settings,
                questionPacks: [pack],
                enabledCategories: ["Factual"]
            )
            Issue.record("Expected insufficient questions error.")
        } catch let error as GameEngineError {
            switch error {
            case .insufficientQuestionsForSession(let required, let available):
                #expect(required == 3)
                #expect(available == 2)
            default:
                Issue.record("Expected .insufficientQuestionsForSession, got \(error.localizedDescription)")
            }
        }
    }
}

private func makePack(questions: [Question]) -> QuestionPack {
    QuestionPack(
        id: "pack",
        title: "Pack",
        languageCode: "en",
        questions: questions
    )
}

private func makeQuestion(id: String, category: String) -> Question {
    Question(
        id: id,
        category: category,
        prompt: "Prompt \(id)",
        validationStyle: .factual,
        sourceURL: URL(string: "https://example.com/\(id)")!,
        answers: makeAnswers()
    )
}

private func makeAnswers() -> [AnswerOption] {
    [
        AnswerOption(text: "A1", points: 1),
        AnswerOption(text: "A2", points: 1),
        AnswerOption(text: "A3", points: 1),
        AnswerOption(text: "A4", points: 1),
        AnswerOption(text: "A5", points: 1),
        AnswerOption(text: "A6", points: 1),
        AnswerOption(text: "A7", points: 1),
        AnswerOption(text: "A8", points: 1),
        AnswerOption(text: "A9", points: 1),
        AnswerOption(text: "A10", points: 1)
    ]
}
