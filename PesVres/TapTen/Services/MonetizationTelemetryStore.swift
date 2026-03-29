import Foundation
import OSLog

enum MonetizationTelemetryEventKind: String, Codable, Equatable, Sendable {
    case firstGameStarted
    case firstGameCompleted
    case packBrowserOpened
    case purchaseStarted
    case purchaseCompleted
    case restoreCompleted
}

struct MonetizationTelemetryEvent: Codable, Equatable, Sendable {
    let kind: MonetizationTelemetryEventKind
    let timestamp: Date
    let packID: String?
    let productID: String?
}

final class MonetizationTelemetryStore {
    static let shared = MonetizationTelemetryStore()

    private enum Keys {
        static let events = "monetizationTelemetry.events"
        static let hasRecordedFirstGameStarted = "monetizationTelemetry.hasRecordedFirstGameStarted"
        static let hasRecordedFirstGameCompleted = "monetizationTelemetry.hasRecordedFirstGameCompleted"
    }

    private static let maxStoredEvents = 200
    private static let logger = Logger(
        subsystem: "TapTen",
        category: "MonetizationTelemetry"
    )

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private(set) var events: [MonetizationTelemetryEvent]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: Keys.events),
           let decodedEvents = try? decoder.decode([MonetizationTelemetryEvent].self, from: data) {
            self.events = decodedEvents
        } else {
            self.events = []
        }
    }

    func recordFirstGameStartedIfNeeded() {
        guard !defaults.bool(forKey: Keys.hasRecordedFirstGameStarted) else {
            return
        }

        defaults.set(true, forKey: Keys.hasRecordedFirstGameStarted)
        record(.firstGameStarted)
    }

    func recordFirstGameCompletedIfNeeded() {
        guard !defaults.bool(forKey: Keys.hasRecordedFirstGameCompleted) else {
            return
        }

        defaults.set(true, forKey: Keys.hasRecordedFirstGameCompleted)
        record(.firstGameCompleted)
    }

    func recordPackBrowserOpened() {
        record(.packBrowserOpened)
    }

    func recordPurchaseStarted(packID: String?, productID: String?) {
        record(.purchaseStarted, packID: packID, productID: productID)
    }

    func recordPurchaseCompleted(packID: String?, productID: String?) {
        record(.purchaseCompleted, packID: packID, productID: productID)
    }

    func recordRestoreCompleted() {
        record(.restoreCompleted)
    }

    private func record(
        _ kind: MonetizationTelemetryEventKind,
        packID: String? = nil,
        productID: String? = nil
    ) {
        let event = MonetizationTelemetryEvent(
            kind: kind,
            timestamp: Date(),
            packID: normalizedValue(packID),
            productID: normalizedValue(productID)
        )

        events.append(event)
        if events.count > Self.maxStoredEvents {
            events.removeFirst(events.count - Self.maxStoredEvents)
        }

        persistEvents()
        Self.logger.debug(
            "Recorded monetization event \(event.kind.rawValue, privacy: .public) packID=\(event.packID ?? "-", privacy: .public) productID=\(event.productID ?? "-", privacy: .public)"
        )
    }

    private func persistEvents() {
        guard let data = try? encoder.encode(events) else {
            return
        }

        defaults.set(data, forKey: Keys.events)
    }

    private func normalizedValue(_ value: String?) -> String? {
        let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmedValue.isEmpty ? nil : trimmedValue
    }
}
