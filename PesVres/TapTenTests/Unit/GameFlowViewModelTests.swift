import Foundation
import Testing
@testable import TapTen

struct GameFlowViewModelTests {
    @Test
    func passDeviceSassyCommentUsesLowTierAfterNonFinalRoundWithFewAnswers() {
        let viewModel = GameFlowViewModel(
            settings: GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 2, roundDurationSeconds: 60),
            enabledCategoryNames: ["Factual"],
            questionPacks: [makePack(questionCount: 2)],
            randomIndexProvider: { _ in 0 },
            randomSassyCommentProvider: { comments in
                comments.first ?? ""
            }
        )

        #expect(viewModel.passDeviceSassyComment == nil)

        viewModel.startRound()
        viewModel.finalizeActiveRoundIfNeeded()
        viewModel.continueAfterRoundSummary()

        #expect(viewModel.phase == .passDevice)
        #expect(viewModel.passDeviceSassyComment == "That round was mostly vibes and very few answers.")
    }

    @Test
    func passDeviceSassyCommentUsesTopTierWhenMostAnswersAreRevealed() throws {
        let viewModel = GameFlowViewModel(
            settings: GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 2, roundDurationSeconds: 60),
            enabledCategoryNames: ["Factual"],
            questionPacks: [makePack(questionCount: 2)],
            randomIndexProvider: { _ in 0 },
            randomSassyCommentProvider: { comments in
                comments.first ?? ""
            }
        )

        viewModel.startRound()
        let hostRoundViewModel = try #require(viewModel.hostRoundViewModel)
        for index in 0..<10 {
            hostRoundViewModel.toggleAnswer(at: index)
        }

        viewModel.finalizeActiveRoundIfNeeded()
        viewModel.continueAfterRoundSummary()

        #expect(viewModel.phase == .passDevice)
        #expect(viewModel.passDeviceSassyComment == "Absolute demolition. Please leave some points for society.")

        viewModel.startRound()
        viewModel.finalizeActiveRoundIfNeeded()
        viewModel.continueAfterRoundSummary()

        #expect(viewModel.phase == .finalResults)
        #expect(viewModel.passDeviceSassyComment == nil)
    }
}

private func makePack(questionCount: Int) -> QuestionPack {
    let questionTotal = max(questionCount, 1)
    let questions = (1...questionTotal).map { index in
        makeQuestion(id: "q\(index)")
    }

    return QuestionPack(
        id: "pack",
        title: "Pack",
        languageCode: "en",
        questions: questions
    )
}

private func makeQuestion(id: String) -> Question {
    Question(
        id: id,
        category: "Factual",
        prompt: "Sample prompt \(id)",
        validationStyle: .factual,
        sourceURL: URL(string: "https://example.com/source/\(id)")!,
        answers: [
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
    )
}
