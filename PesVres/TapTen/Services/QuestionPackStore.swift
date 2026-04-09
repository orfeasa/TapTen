import Foundation
import Observation
import StoreKit

enum QuestionPackAvailability: Equatable {
    case included
    case locked
    case unlocked
}

enum QuestionPackStoreActionState: Equatable {
    case unavailable
    case ready(price: String?)
    case testerUnlock
    case purchasing
}

@Observable
final class QuestionPackEntitlementStore {
    static let shared = QuestionPackEntitlementStore()

    private enum Keys {
        static let unlockedProductIDs = "packs.unlockedProductIDs"
    }

    private let defaults: UserDefaults

    private(set) var unlockedProductIDs: Set<String>

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let storedProductIDs = defaults.stringArray(forKey: Keys.unlockedProductIDs) ?? []
        self.unlockedProductIDs = Set(storedProductIDs)
    }

    func availability(for pack: QuestionPack) -> QuestionPackAvailability {
        switch pack.access {
        case .free:
            return .included
        case .premium:
            let unlockingProductIDs = Set(
                [pack.storeProductID].compactMap { $0 } + pack.bundleProductIDs
            )

            guard !unlockingProductIDs.isEmpty else {
                return .locked
            }

            return unlockingProductIDs.isDisjoint(with: unlockedProductIDs) ? .locked : .unlocked
        }
    }

    func accessiblePacks(from packs: [QuestionPack]) -> [QuestionPack] {
        packs.filter { availability(for: $0) != .locked }
    }

    func setUnlockedProductIDs(_ productIDs: Set<String>) {
        unlockedProductIDs = productIDs
        defaults.set(Array(productIDs).sorted(), forKey: Keys.unlockedProductIDs)
    }

    func markUnlocked(productID: String) {
        guard !productID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        var updated = unlockedProductIDs
        updated.insert(productID)
        setUnlockedProductIDs(updated)
    }
}

@MainActor
@Observable
final class QuestionPackStorefront {
    static let shared = QuestionPackStorefront()

    private let entitlementStore: QuestionPackEntitlementStore
    private let monetizationTelemetryStore: MonetizationTelemetryStore
    private let testerUnlocksEnabledProvider: @Sendable () -> Bool

    private(set) var isRefreshing = false
    private(set) var isRestoringPurchases = false
    private(set) var purchasingProductID: String?
    private(set) var productsByID: [String: Product] = [:]
    private(set) var storeMessage: String?

    init(
        entitlementStore: QuestionPackEntitlementStore? = nil,
        monetizationTelemetryStore: MonetizationTelemetryStore? = nil,
        testerUnlocksEnabledProvider: @escaping @Sendable () -> Bool = {
            QuestionPackTestingConfiguration.testerUnlocksEnabled()
        }
    ) {
        self.entitlementStore = entitlementStore ?? .shared
        self.monetizationTelemetryStore = monetizationTelemetryStore ?? .shared
        self.testerUnlocksEnabledProvider = testerUnlocksEnabledProvider
    }

    var isUsingTesterUnlocks: Bool {
        testerUnlocksEnabledProvider()
    }

    func refreshStoreData(for packs: [QuestionPack]) async {
        guard !isRefreshing else {
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        guard !isUsingTesterUnlocks else {
            productsByID = [:]
            storeMessage = nil
            return
        }

        let premiumProductIDs = Set(
            packs
                .filter(\.isPremium)
                .compactMap(\.storeProductID)
        )

        if premiumProductIDs.isEmpty {
            productsByID = [:]
            storeMessage = nil
            return
        }

        do {
            let products = try await Product.products(for: Array(premiumProductIDs).sorted())
            productsByID = Dictionary(uniqueKeysWithValues: products.map { ($0.id, $0) })
            await syncUnlockedProductIDs()
            storeMessage = nil
        } catch {
            storeMessage = "Store details are unavailable right now."
        }
    }

    func restorePurchases(for packs: [QuestionPack]) async {
        guard !isRestoringPurchases else {
            return
        }

        guard !isUsingTesterUnlocks else {
            storeMessage = "Tester builds unlock packs directly. Restore is not needed."
            return
        }

        isRestoringPurchases = true
        defer { isRestoringPurchases = false }

        do {
            try await AppStore.sync()
            await refreshStoreData(for: packs)
            monetizationTelemetryStore.recordRestoreCompleted()
            storeMessage = "Purchases restored."
        } catch {
            storeMessage = "Couldn't restore purchases right now."
        }
    }

    func purchase(_ pack: QuestionPack, availablePacks: [QuestionPack]) async {
        guard let productID = pack.storeProductID else {
            storeMessage = "This pack is not ready for purchase yet."
            return
        }

        purchasingProductID = productID
        defer { purchasingProductID = nil }
        monetizationTelemetryStore.recordPurchaseStarted(packID: pack.id, productID: productID)

        if isUsingTesterUnlocks {
            entitlementStore.markUnlocked(productID: productID)
            monetizationTelemetryStore.recordPurchaseCompleted(
                packID: pack.id,
                productID: productID
            )
            storeMessage = "\(pack.title) unlocked for testing."
            return
        }

        if productsByID[productID] == nil {
            await refreshStoreData(for: availablePacks)
        }

        guard let product = productsByID[productID] else {
            storeMessage = "Store details are unavailable right now."
            return
        }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                let transaction = try verifiedTransaction(from: verificationResult)
                entitlementStore.markUnlocked(productID: transaction.productID)
                monetizationTelemetryStore.recordPurchaseCompleted(
                    packID: pack.id,
                    productID: transaction.productID
                )
                await transaction.finish()
                storeMessage = "\(pack.title) unlocked."
            case .pending:
                storeMessage = "Purchase pending approval."
            case .userCancelled:
                storeMessage = nil
            @unknown default:
                storeMessage = "Purchase didn't complete."
            }
        } catch {
            storeMessage = "Couldn't complete the purchase right now."
        }
    }

    func actionState(for pack: QuestionPack) -> QuestionPackStoreActionState {
        switch entitlementStore.availability(for: pack) {
        case .included, .unlocked:
            return .unavailable
        case .locked:
            guard let productID = pack.storeProductID else {
                return .unavailable
            }

            if purchasingProductID == productID {
                return .purchasing
            }

            if isUsingTesterUnlocks {
                return .testerUnlock
            }

            return .ready(price: productsByID[productID]?.displayPrice)
        }
    }

    func isUnlocked(_ pack: QuestionPack) -> Bool {
        entitlementStore.availability(for: pack) == .unlocked
    }

    private func syncUnlockedProductIDs() async {
        var unlockedProductIDs: Set<String> = []

        for await verificationResult in Transaction.currentEntitlements {
            guard let transaction = try? verifiedTransaction(from: verificationResult) else {
                continue
            }

            unlockedProductIDs.insert(transaction.productID)
        }

        entitlementStore.setUnlockedProductIDs(unlockedProductIDs)
    }

    private func verifiedTransaction(
        from result: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            throw StoreKitError.notEntitled
        }
    }
}

enum QuestionPackTestingConfiguration {
    nonisolated static func testerUnlocksEnabled(
        bundle: Bundle = .main,
        processInfo: ProcessInfo = .processInfo
    ) -> Bool {
        if let parsedEnvironmentValue = parsedBool(
            processInfo.environment["TAPTEN_TESTER_UNLOCKS_ENABLED"]
        ) {
            return parsedEnvironmentValue
        }

        #if TAPTEN_TESTER_UNLOCKS_ENABLED
        return true
        #else
        return inferredTesterUnlocksEnabled(
            infoDictionaryValue: bundle.object(
                forInfoDictionaryKey: "QuestionPackTesterUnlocksEnabled"
            ),
            receiptURL: bundle.appStoreReceiptURL
        )
        #endif
    }

    nonisolated static func inferredTesterUnlocksEnabled(
        infoDictionaryValue: Any?,
        receiptURL: URL?
    ) -> Bool {
        if let parsedInfoDictionaryValue = parsedInfoDictionaryValue(infoDictionaryValue) {
            return parsedInfoDictionaryValue
        }

        return isSandboxReceipt(receiptURL)
    }

    private nonisolated static func parsedBool(_ rawValue: String?) -> Bool? {
        let normalized = rawValue?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        switch normalized {
        case "1", "true", "yes", "on":
            return true
        case "0", "false", "no", "off":
            return false
        default:
            return nil
        }
    }

    private nonisolated static func parsedInfoDictionaryValue(_ rawValue: Any?) -> Bool? {
        if let boolValue = rawValue as? Bool {
            return boolValue
        }

        if let stringValue = rawValue as? String,
           let parsedStringValue = parsedBool(stringValue) {
            return parsedStringValue
        }

        if let numericValue = rawValue as? NSNumber {
            return numericValue.boolValue
        }

        return nil
    }

    private nonisolated static func isSandboxReceipt(_ receiptURL: URL?) -> Bool {
        receiptURL?.lastPathComponent == "sandboxReceipt"
    }
}
