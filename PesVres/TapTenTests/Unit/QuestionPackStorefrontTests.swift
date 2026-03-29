import Foundation
import Testing
@testable import TapTen

@MainActor
struct QuestionPackStorefrontTests {
    @Test
    func testerUnlockStateShowsUnlockActionWithoutStorePricing() throws {
        let defaults = try makeDefaults()
        let storefront = QuestionPackStorefront(
            entitlementStore: QuestionPackEntitlementStore(defaults: defaults),
            monetizationTelemetryStore: MonetizationTelemetryStore(defaults: defaults),
            testerUnlocksEnabledProvider: { true }
        )

        let actionState = storefront.actionState(for: makePack())

        #expect(actionState == .testerUnlock)
        #expect(storefront.isUsingTesterUnlocks)
    }

    @Test
    func purchaseUnlocksPremiumPackLocallyInTesterMode() async throws {
        let defaults = try makeDefaults()
        let entitlementStore = QuestionPackEntitlementStore(defaults: defaults)
        let telemetryStore = MonetizationTelemetryStore(defaults: defaults)
        let storefront = QuestionPackStorefront(
            entitlementStore: entitlementStore,
            monetizationTelemetryStore: telemetryStore,
            testerUnlocksEnabledProvider: { true }
        )
        let pack = makePack()

        await storefront.purchase(pack, availablePacks: [pack])

        #expect(entitlementStore.availability(for: pack) == .unlocked)
        #expect(storefront.storeMessage == "Premium Pack unlocked for testing.")
        #expect(telemetryStore.events.map(\.kind) == [.purchaseStarted, .purchaseCompleted])
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "QuestionPackStorefrontTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private func makePack() -> QuestionPack {
    QuestionPack(
        id: "premium-pack",
        title: "Premium Pack",
        languageCode: "en",
        questions: [
            Question(
                id: "q1",
                category: "Premium",
                prompt: "Prompt",
                difficulty: .medium,
                validationStyle: .editorial,
                sourceURL: URL(string: "https://example.com")!,
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
        ],
        monetization: QuestionPackMonetization(
            access: .premium,
            storeProductID: "com.tapten.pack.premium"
        )
    )
}
