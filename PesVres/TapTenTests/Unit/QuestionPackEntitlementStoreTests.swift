import Foundation
import Testing
@testable import TapTen

struct QuestionPackEntitlementStoreTests {
    @Test
    func freePacksAreAlwaysAccessible() throws {
        let defaults = try makeDefaults()
        let store = QuestionPackEntitlementStore(defaults: defaults)
        let pack = makePack(access: .free)

        #expect(store.availability(for: pack) == .included)
        #expect(store.accessiblePacks(from: [pack]) == [pack])
    }

    @Test
    func premiumPacksStartLockedUntilUnlockedProductIDIsStored() throws {
        let defaults = try makeDefaults()
        let store = QuestionPackEntitlementStore(defaults: defaults)
        let pack = makePack(
            id: "premium-pack",
            access: .premium,
            storeProductID: "com.tapten.pack.premium"
        )

        #expect(store.availability(for: pack) == .locked)
        #expect(store.accessiblePacks(from: [pack]).isEmpty)

        store.markUnlocked(productID: "com.tapten.pack.premium")

        #expect(store.availability(for: pack) == .unlocked)
        #expect(store.accessiblePacks(from: [pack]) == [pack])
    }

    @Test
    func bundleProductIDsAlsoUnlockPremiumPacks() throws {
        let defaults = try makeDefaults()
        let store = QuestionPackEntitlementStore(defaults: defaults)
        let pack = makePack(
            id: "premium-pack",
            access: .premium,
            storeProductID: "com.tapten.pack.after-dark-1",
            bundleProductIDs: ["com.tapten.bundle.launch-wave"]
        )

        #expect(store.availability(for: pack) == .locked)

        store.markUnlocked(productID: "com.tapten.bundle.launch-wave")

        #expect(store.availability(for: pack) == .unlocked)
        #expect(store.accessiblePacks(from: [pack]) == [pack])
    }

    @Test
    func unlockedProductIDsPersistAcrossStoreInstances() throws {
        let defaults = try makeDefaults()
        let firstStore = QuestionPackEntitlementStore(defaults: defaults)
        firstStore.markUnlocked(productID: "com.tapten.pack.bundle")

        let secondStore = QuestionPackEntitlementStore(defaults: defaults)
        #expect(secondStore.unlockedProductIDs == ["com.tapten.pack.bundle"])
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "QuestionPackEntitlementStoreTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private func makePack(
    id: String = "free-pack",
    access: QuestionPackAccess,
    storeProductID: String? = nil,
    bundleProductIDs: [String] = []
) -> QuestionPack {
    QuestionPack(
        id: id,
        title: "Pack",
        languageCode: "en",
        questions: [
            Question(
                id: "q1",
                category: "Factual",
                prompt: "Prompt",
                difficulty: .medium,
                validationStyle: .factual,
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
            access: access,
            storeProductID: storeProductID,
            bundleProductIDs: bundleProductIDs
        )
    )
}
