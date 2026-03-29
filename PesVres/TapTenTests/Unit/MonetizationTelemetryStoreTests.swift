import Foundation
import Testing
@testable import TapTen

struct MonetizationTelemetryStoreTests {
    @Test
    func firstGameEventsAreRecordedOnlyOnceAndPersisted() throws {
        let defaults = try makeDefaults()
        let store = MonetizationTelemetryStore(defaults: defaults)

        store.recordFirstGameStartedIfNeeded()
        store.recordFirstGameStartedIfNeeded()
        store.recordFirstGameCompletedIfNeeded()
        store.recordFirstGameCompletedIfNeeded()

        #expect(store.events.map(\.kind) == [.firstGameStarted, .firstGameCompleted])

        let reloadedStore = MonetizationTelemetryStore(defaults: defaults)
        #expect(reloadedStore.events.map(\.kind) == [.firstGameStarted, .firstGameCompleted])
    }

    @Test
    func packBrowserPurchaseAndRestoreEventsRetainPackAndProductContext() throws {
        let defaults = try makeDefaults()
        let store = MonetizationTelemetryStore(defaults: defaults)

        store.recordPackBrowserOpened()
        store.recordPurchaseStarted(packID: "after-dark-vol-1", productID: "com.tapten.pack.after-dark-vol-1")
        store.recordPurchaseCompleted(packID: "after-dark-vol-1", productID: "com.tapten.pack.after-dark-vol-1")
        store.recordRestoreCompleted()

        #expect(store.events.map(\.kind) == [
            .packBrowserOpened,
            .purchaseStarted,
            .purchaseCompleted,
            .restoreCompleted
        ])
        #expect(store.events[1].packID == "after-dark-vol-1")
        #expect(store.events[1].productID == "com.tapten.pack.after-dark-vol-1")
        #expect(store.events[2].packID == "after-dark-vol-1")
        #expect(store.events[2].productID == "com.tapten.pack.after-dark-vol-1")
    }

    @Test
    func gameFlowViewModelRecordsFirstGameLifecycleEvents() throws {
        let defaults = try makeDefaults()
        let telemetryStore = MonetizationTelemetryStore(defaults: defaults)
        let viewModel = GameFlowViewModel(
            settings: GameSettings(teamAName: "A", teamBName: "B", numberOfRounds: 1, roundDurationSeconds: 60),
            enabledCategoryNames: ["Factual"],
            questionPacks: [makePack(questionCount: 2)],
            monetizationTelemetryStore: telemetryStore,
            randomIndexProvider: { _ in 0 },
            randomSassyCommentProvider: { comments in
                comments.first ?? ""
            }
        )

        #expect(telemetryStore.events.map(\.kind) == [.firstGameStarted])

        viewModel.showQuestionPreview()
        viewModel.startRound()
        viewModel.finalizeActiveRoundIfNeeded()
        viewModel.continueAfterRoundSummary()

        #expect(viewModel.phase == .finalResults)
        #expect(telemetryStore.events.map(\.kind) == [.firstGameStarted, .firstGameCompleted])
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "MonetizationTelemetryStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
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
