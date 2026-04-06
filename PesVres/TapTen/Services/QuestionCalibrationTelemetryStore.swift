import Foundation
import OSLog

struct QuestionCalibrationTelemetryEvent: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let packID: String?
    let packTitle: String?
    let packVersion: String?
    let questionID: String
    let prompt: String
    let category: String
    let difficultyTier: QuestionDifficulty
    let finishReason: HostRoundFinishReason?
    let roundDurationSeconds: Int
    let revealedAnswerIndices: [Int]
    let totalAnswers: Int
    let pointsAwarded: Int
    let remainingTimeAtFinish: TimeInterval
    let timeToFirstReveal: TimeInterval?

    var revealedAnswers: Int {
        revealedAnswerIndices.count
    }

    var completionRatio: Double {
        guard totalAnswers > 0 else {
            return 0
        }

        return Double(revealedAnswers) / Double(totalAnswers)
    }
}

struct QuestionCalibrationSummary: Equatable, Sendable {
    let packID: String?
    let packTitle: String?
    let packVersion: String?
    let questionID: String
    let prompt: String
    let category: String
    let difficultyTier: QuestionDifficulty
    let sampleCount: Int
    let skippedRounds: Int
    let averageRevealedAnswers: Double
    let averageCompletionRatio: Double
    let averagePointsAwarded: Double
    let averageTimeToFirstReveal: TimeInterval?
    let mostRecentPlayedAt: Date

    var skipRate: Double {
        guard sampleCount > 0 else {
            return 0
        }

        return Double(skippedRounds) / Double(sampleCount)
    }
}

struct QuestionDifficultyCalibrationSummary: Equatable, Sendable {
    let difficultyTier: QuestionDifficulty
    let sampleCount: Int
    let skippedRounds: Int
    let averageRevealedAnswers: Double
    let averageCompletionRatio: Double
    let averagePointsAwarded: Double
    let averageTimeToFirstReveal: TimeInterval?

    var skipRate: Double {
        guard sampleCount > 0 else {
            return 0
        }

        return Double(skippedRounds) / Double(sampleCount)
    }
}

final class QuestionCalibrationTelemetryStore {
    static let shared = QuestionCalibrationTelemetryStore()

    private enum Keys {
        static let events = "questionCalibrationTelemetry.events"
    }

    private struct QuestionSummaryKey: Hashable {
        let packID: String?
        let packVersion: String?
        let questionID: String
    }

    private static let maxStoredEvents = 1_000
    private static let logger = Logger(
        subsystem: "TapTen",
        category: "QuestionCalibrationTelemetry"
    )

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private(set) var events: [QuestionCalibrationTelemetryEvent]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if let data = defaults.data(forKey: Keys.events),
           let decodedEvents = try? decoder.decode([QuestionCalibrationTelemetryEvent].self, from: data) {
            self.events = decodedEvents
        } else {
            self.events = []
        }
    }

    func recordRoundOutcome(
        context: QuestionFeedbackContext,
        roundDurationSeconds: Int,
        finishReason: HostRoundFinishReason?,
        revealedAnswerIndices: Set<Int>,
        totalAnswers: Int,
        pointsAwarded: Int,
        remainingTimeAtFinish: TimeInterval,
        timeToFirstReveal: TimeInterval?
    ) {
        let clampedRoundDuration = max(roundDurationSeconds, 1)
        let clampedTotalAnswers = max(totalAnswers, 0)
        let event = QuestionCalibrationTelemetryEvent(
            id: UUID(),
            timestamp: Date(),
            packID: normalizedValue(context.packID),
            packTitle: normalizedValue(context.packTitle),
            packVersion: normalizedValue(context.packVersion),
            questionID: context.questionID,
            prompt: context.prompt,
            category: context.category,
            difficultyTier: context.difficultyTier,
            finishReason: finishReason,
            roundDurationSeconds: clampedRoundDuration,
            revealedAnswerIndices: revealedAnswerIndices.sorted(),
            totalAnswers: clampedTotalAnswers,
            pointsAwarded: max(pointsAwarded, 0),
            remainingTimeAtFinish: clampedTime(
                remainingTimeAtFinish,
                maximum: TimeInterval(clampedRoundDuration)
            ) ?? 0,
            timeToFirstReveal: clampedTime(
                timeToFirstReveal,
                maximum: TimeInterval(clampedRoundDuration)
            )
        )

        events.append(event)
        if events.count > Self.maxStoredEvents {
            events.removeFirst(events.count - Self.maxStoredEvents)
        }

        persistEvents()
        Self.logger.debug(
            "Recorded question outcome questionID=\(event.questionID, privacy: .public) tier=\(event.difficultyTier.rawValue, privacy: .public) finish=\(event.finishReason?.rawValue ?? "unknown", privacy: .public) revealed=\(event.revealedAnswers) points=\(event.pointsAwarded)"
        )
    }

    func questionSummaries() -> [QuestionCalibrationSummary] {
        let groupedEvents = Dictionary(grouping: events) { event in
            QuestionSummaryKey(
                packID: event.packID,
                packVersion: event.packVersion,
                questionID: event.questionID
            )
        }

        return groupedEvents.values
            .map(makeQuestionSummary)
            .sorted { lhs, rhs in
                let lhsPackID = lhs.packID ?? ""
                let rhsPackID = rhs.packID ?? ""
                if lhsPackID != rhsPackID {
                    return lhsPackID < rhsPackID
                }

                let lhsPackVersion = lhs.packVersion ?? ""
                let rhsPackVersion = rhs.packVersion ?? ""
                if lhsPackVersion != rhsPackVersion {
                    return lhsPackVersion < rhsPackVersion
                }

                return lhs.questionID < rhs.questionID
            }
    }

    func difficultySummaries() -> [QuestionDifficultyCalibrationSummary] {
        QuestionDifficulty.allCases.compactMap { difficultyTier in
            let matchingEvents = events.filter { $0.difficultyTier == difficultyTier }
            guard !matchingEvents.isEmpty else {
                return nil
            }

            return makeDifficultySummary(
                difficultyTier: difficultyTier,
                events: matchingEvents
            )
        }
    }

    func pendingEvents() -> [QuestionCalibrationTelemetryEvent] {
        events
    }

    func removeEvents(withIDs ids: Set<UUID>) {
        guard !ids.isEmpty else {
            return
        }

        events.removeAll { ids.contains($0.id) }
        persistEvents()
    }

    private func makeQuestionSummary(
        from matchingEvents: [QuestionCalibrationTelemetryEvent]
    ) -> QuestionCalibrationSummary {
        let sortedEvents = matchingEvents.sorted { $0.timestamp < $1.timestamp }
        let latestEvent = sortedEvents.last ?? matchingEvents[0]

        return QuestionCalibrationSummary(
            packID: latestEvent.packID,
            packTitle: latestEvent.packTitle,
            packVersion: latestEvent.packVersion,
            questionID: latestEvent.questionID,
            prompt: latestEvent.prompt,
            category: latestEvent.category,
            difficultyTier: latestEvent.difficultyTier,
            sampleCount: matchingEvents.count,
            skippedRounds: matchingEvents.filter { $0.finishReason == .skipped }.count,
            averageRevealedAnswers: average(
                matchingEvents.map { Double($0.revealedAnswers) }
            ),
            averageCompletionRatio: average(
                matchingEvents.map(\.completionRatio)
            ),
            averagePointsAwarded: average(
                matchingEvents.map { Double($0.pointsAwarded) }
            ),
            averageTimeToFirstReveal: averageTimeInterval(
                matchingEvents.compactMap(\.timeToFirstReveal)
            ),
            mostRecentPlayedAt: latestEvent.timestamp
        )
    }

    private func makeDifficultySummary(
        difficultyTier: QuestionDifficulty,
        events: [QuestionCalibrationTelemetryEvent]
    ) -> QuestionDifficultyCalibrationSummary {
        QuestionDifficultyCalibrationSummary(
            difficultyTier: difficultyTier,
            sampleCount: events.count,
            skippedRounds: events.filter { $0.finishReason == .skipped }.count,
            averageRevealedAnswers: average(events.map { Double($0.revealedAnswers) }),
            averageCompletionRatio: average(events.map(\.completionRatio)),
            averagePointsAwarded: average(events.map { Double($0.pointsAwarded) }),
            averageTimeToFirstReveal: averageTimeInterval(events.compactMap(\.timeToFirstReveal))
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

    private func clampedTime(_ value: TimeInterval?, maximum: TimeInterval) -> TimeInterval? {
        guard let value else {
            return nil
        }

        return min(max(value, 0), maximum)
    }

    private func average(_ values: [Double]) -> Double {
        guard !values.isEmpty else {
            return 0
        }

        return values.reduce(0, +) / Double(values.count)
    }

    private func averageTimeInterval(_ values: [TimeInterval]) -> TimeInterval? {
        guard !values.isEmpty else {
            return nil
        }

        return values.reduce(0, +) / Double(values.count)
    }
}
