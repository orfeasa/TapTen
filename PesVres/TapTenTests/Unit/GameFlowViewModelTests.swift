import Foundation
import Testing
@testable import TapTen

struct GameFlowViewModelTests {
    @Test
    func finalSassyCommentUsesLowTierWhenAlmostNoAnswersAreRevealed() {
        let viewModel = GameFlowViewModel(
            settings: GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 1, roundDurationSeconds: 60),
            enabledCategoryNames: ["Factual"],
            questionPacks: [makePack()],
            randomIndexProvider: { _ in 0 },
            randomSassyCommentProvider: { comments in
                comments.first ?? ""
            }
        )

        viewModel.startRound()
        viewModel.finalizeActiveRoundIfNeeded()
        viewModel.continueAfterRoundSummary()

        #expect(viewModel.phase == .finalResults)
        #expect(viewModel.finalSassyComment == "That round was mostly vibes and very few answers.")
    }

    @Test
    func finalSassyCommentUsesTopTierWhenMostAnswersAreRevealed() throws {
        let viewModel = GameFlowViewModel(
            settings: GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 1, roundDurationSeconds: 60),
            enabledCategoryNames: ["Factual"],
            questionPacks: [makePack()],
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

        #expect(viewModel.phase == .finalResults)
        #expect(viewModel.finalSassyComment == "Absolute demolition. Please leave some points for society.")
    }
}

private func makePack() -> QuestionPack {
    QuestionPack(
        id: "pack",
        title: "Pack",
        languageCode: "en",
        questions: [
            Question(
                id: "q1",
                category: "Factual",
                prompt: "Sample prompt",
                validationStyle: .factual,
                sourceURL: URL(string: "https://example.com/source")!,
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
        ]
    )
}
