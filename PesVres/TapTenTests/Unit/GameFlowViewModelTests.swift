import Foundation
import Testing
@testable import TapTen

struct GameFlowViewModelTests {
#if DEBUG
    @Test
    func recordsDebugTelemetryOnRoundSummaryAndClearsOnPlayAgain() {
        let viewModel = GameFlowViewModel(
            settings: GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 1, roundDurationSeconds: 60),
            enabledCategoryNames: ["Factual"],
            questionPacks: [makePack(questionCount: 2)],
            randomIndexProvider: { _ in 0 },
            randomSassyCommentProvider: { comments in
                comments.first ?? ""
            }
        )

        viewModel.startRound()
        let hostRoundViewModel = viewModel.hostRoundViewModel
        hostRoundViewModel?.endRound()
        viewModel.finalizeActiveRoundIfNeeded()

        #expect(viewModel.debugRoundTelemetry.count == 1)
        #expect(viewModel.debugRoundTelemetry.first?.category == "Factual")

        viewModel.continueAfterRoundSummary()
        #expect(viewModel.phase == .finalResults)

        viewModel.playAgain()
        #expect(viewModel.debugRoundTelemetry.isEmpty)
    }
#endif

    @Test
    func summaryContinueButtonTitleMatchesRoundState() {
        let viewModel = GameFlowViewModel(
            settings: GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 1, roundDurationSeconds: 60),
            enabledCategoryNames: ["Factual"],
            questionPacks: [makePack(questionCount: 4)],
            randomIndexProvider: { _ in 0 },
            randomSassyCommentProvider: { comments in
                comments.first ?? ""
            }
        )

        viewModel.startRound()
        viewModel.finalizeActiveRoundIfNeeded()
        #expect(viewModel.phase == .roundSummary)
        #expect(viewModel.summaryContinueButtonTitle == "Next Round")

        viewModel.continueAfterRoundSummary()
        viewModel.startRound()
        viewModel.finalizeActiveRoundIfNeeded()
        #expect(viewModel.phase == .roundSummary)
        #expect(viewModel.summaryContinueButtonTitle == "Continue to Final Results")
    }

    @Test
    func roundSummarySassyCommentUsesLowTierWhenFewAnswersAreRevealed() {
        let viewModel = GameFlowViewModel(
            settings: GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 1, roundDurationSeconds: 60),
            enabledCategoryNames: ["Factual"],
            questionPacks: [makePack(questionCount: 2)],
            randomIndexProvider: { _ in 0 },
            randomSassyCommentProvider: { comments in
                comments.first ?? ""
            }
        )

        viewModel.startRound()
        viewModel.finalizeActiveRoundIfNeeded()

        #expect(viewModel.phase == .roundSummary)
        #expect(viewModel.latestRoundSummary?.sassyComment == "That round was mostly vibes and very few answers.")
    }

    @Test
    func roundSummarySassyCommentUsesTopTierWhenMostAnswersAreRevealed() throws {
        let viewModel = GameFlowViewModel(
            settings: GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 1, roundDurationSeconds: 60),
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

        #expect(viewModel.phase == .roundSummary)
        #expect(viewModel.latestRoundSummary?.sassyComment == "Absolute demolition. Please leave some points for society.")
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
        difficulty: .medium,
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
