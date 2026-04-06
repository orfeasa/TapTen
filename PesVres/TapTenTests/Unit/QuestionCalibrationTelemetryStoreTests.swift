import Foundation
import Testing
@testable import TapTen

struct QuestionCalibrationTelemetryStoreTests {
    @Test
    func roundOutcomesPersistAndQuestionSummariesAggregateCalibrationSignals() throws {
        let defaults = try makeDefaults()
        let store = QuestionCalibrationTelemetryStore(defaults: defaults)
        let context = makeContext(questionID: "q1", difficultyTier: .medium)

        store.recordRoundOutcome(
            context: context,
            roundDurationSeconds: 60,
            finishReason: .timerExpired,
            revealedAnswerIndices: [0, 1, 4],
            totalAnswers: 10,
            pointsAwarded: 7,
            remainingTimeAtFinish: 0,
            timeToFirstReveal: 1.2
        )
        store.recordRoundOutcome(
            context: context,
            roundDurationSeconds: 60,
            finishReason: .skipped,
            revealedAnswerIndices: [0],
            totalAnswers: 10,
            pointsAwarded: 1,
            remainingTimeAtFinish: 42,
            timeToFirstReveal: 3.0
        )

        #expect(store.events.count == 2)

        let reloadedStore = QuestionCalibrationTelemetryStore(defaults: defaults)
        #expect(reloadedStore.events.count == 2)

        let summary = try #require(reloadedStore.questionSummaries().first)
        #expect(summary.questionID == "q1")
        #expect(summary.difficultyTier == .medium)
        #expect(summary.sampleCount == 2)
        #expect(summary.skippedRounds == 1)
        #expect(abs(summary.averageRevealedAnswers - 2.0) < 0.0001)
        #expect(abs(summary.averageCompletionRatio - 0.2) < 0.0001)
        #expect(abs(summary.averagePointsAwarded - 4.0) < 0.0001)
        #expect(abs(summary.skipRate - 0.5) < 0.0001)
        #expect(abs((summary.averageTimeToFirstReveal ?? 0) - 2.1) < 0.0001)
    }

    @Test
    func difficultySummariesShowWhetherEasyActuallyPerformsAboveHard() throws {
        let store = QuestionCalibrationTelemetryStore(defaults: try makeDefaults())

        store.recordRoundOutcome(
            context: makeContext(questionID: "easy-q", difficultyTier: .easy),
            roundDurationSeconds: 60,
            finishReason: .timerExpired,
            revealedAnswerIndices: [0, 1, 2, 3, 4, 5, 6, 7],
            totalAnswers: 10,
            pointsAwarded: 13,
            remainingTimeAtFinish: 0,
            timeToFirstReveal: 0.8
        )
        store.recordRoundOutcome(
            context: makeContext(questionID: "hard-q", difficultyTier: .hard),
            roundDurationSeconds: 60,
            finishReason: .skipped,
            revealedAnswerIndices: [0, 3],
            totalAnswers: 10,
            pointsAwarded: 4,
            remainingTimeAtFinish: 37,
            timeToFirstReveal: 3.4
        )

        let summaries = store.difficultySummaries()
        #expect(summaries.map(\.difficultyTier) == [.easy, .hard])

        let easySummary = try #require(summaries.first)
        let hardSummary = try #require(summaries.last)

        #expect(easySummary.averageRevealedAnswers > hardSummary.averageRevealedAnswers)
        #expect(easySummary.averageCompletionRatio > hardSummary.averageCompletionRatio)
        #expect(easySummary.skipRate < hardSummary.skipRate)
    }

    @Test
    func gameFlowRecordsQuestionCalibrationOutcomeOnRoundSummary() throws {
        let defaults = try makeDefaults()
        let telemetryStore = QuestionCalibrationTelemetryStore(defaults: defaults)
        let viewModel = GameFlowViewModel(
            settings: GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 1, roundDurationSeconds: 60),
            enabledCategoryNames: ["Factual"],
            questionPacks: [makePack(questionCount: 1)],
            questionCalibrationTelemetryStore: telemetryStore,
            randomIndexProvider: { _ in 0 },
            randomSassyCommentProvider: { comments in
                comments.first ?? ""
            }
        )

        viewModel.showQuestionPreview()
        viewModel.startRound()
        let hostRoundViewModel = try #require(viewModel.hostRoundViewModel)
        advanceTicks(hostRoundViewModel, count: 15)
        hostRoundViewModel.revealAnswer(at: 0)
        hostRoundViewModel.revealAnswer(at: 2)
        hostRoundViewModel.skipRound()

        viewModel.finalizeActiveRoundIfNeeded()

        let event = try #require(telemetryStore.events.first)
        #expect(event.questionID == "q1")
        #expect(event.difficultyTier == .medium)
        #expect(event.finishReason == .skipped)
        #expect(event.revealedAnswerIndices == [0, 2])
        #expect(abs((event.timeToFirstReveal ?? 0) - 1.5) < 0.0001)
        #expect(abs(event.remainingTimeAtFinish - 58.5) < 0.0001)
    }

    @Test
    func removeEventsWithIDsOnlyDropsDeliveredEvents() throws {
        let store = QuestionCalibrationTelemetryStore(defaults: try makeDefaults())

        store.recordRoundOutcome(
            context: makeContext(questionID: "q1", difficultyTier: .medium),
            roundDurationSeconds: 60,
            finishReason: .timerExpired,
            revealedAnswerIndices: [0, 1],
            totalAnswers: 10,
            pointsAwarded: 4,
            remainingTimeAtFinish: 0,
            timeToFirstReveal: 1.0
        )
        store.recordRoundOutcome(
            context: makeContext(questionID: "q2", difficultyTier: .hard),
            roundDurationSeconds: 60,
            finishReason: .skipped,
            revealedAnswerIndices: [0],
            totalAnswers: 10,
            pointsAwarded: 1,
            remainingTimeAtFinish: 32,
            timeToFirstReveal: 2.5
        )

        let firstEventID = try #require(store.events.first?.id)
        store.removeEvents(withIDs: [firstEventID])

        #expect(store.events.count == 1)
        #expect(store.events.first?.questionID == "q2")
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "QuestionCalibrationTelemetryStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    private func makeContext(
        questionID: String,
        difficultyTier: QuestionDifficulty
    ) -> QuestionFeedbackContext {
        QuestionFeedbackContext(
            packID: "pack",
            packTitle: "Pack",
            packVersion: "1.0",
            questionID: questionID,
            prompt: "Prompt \(questionID)",
            category: "Factual",
            difficultyTier: difficultyTier,
            validationStyle: .factual,
            sourceURL: URL(string: "https://example.com/\(questionID)")!
        )
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
        questions: questions,
        packVersion: "1.0"
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

private func advanceTicks(_ viewModel: HostRoundViewModel, count: Int) {
    for _ in 0..<count {
        viewModel.processTickForTesting()
    }
}
