import Foundation
import Testing
@testable import TapTen

struct QuestionCalibrationSubmissionServiceTests {
    @Test
    func submitPendingEventsDoesNothingWhenStoreIsEmpty() async throws {
        let service = QuestionCalibrationSubmissionService(
            transport: RecordingQuestionCalibrationTransport(),
            store: QuestionCalibrationTelemetryStore(defaults: try makeDefaults()),
            endpointProvider: { URL(string: "https://example.com/calibration") }
        )

        let status = await service.submitPendingEventsIfPossible()

        #expect(status == nil)
        #expect(await service.pendingEventCount() == 0)
    }

    @Test
    func pendingEventsRemainWhenEndpointIsUnavailable() async throws {
        let store = QuestionCalibrationTelemetryStore(defaults: try makeDefaults())
        store.recordRoundOutcome(
            context: Self.sampleContext(),
            roundDurationSeconds: 60,
            finishReason: .timerExpired,
            revealedAnswerIndices: [0, 1],
            totalAnswers: 10,
            pointsAwarded: 4,
            remainingTimeAtFinish: 0,
            timeToFirstReveal: 1.0
        )

        let service = QuestionCalibrationSubmissionService(
            transport: RecordingQuestionCalibrationTransport(),
            store: store,
            endpointProvider: { nil }
        )

        let status = await service.submitPendingEventsIfPossible()

        #expect(status == .savedPendingConfiguration)
        #expect(await service.pendingEventCount() == 1)
    }

    @Test
    func submitPendingEventsSendsBatchAndClearsStore() async throws {
        let store = QuestionCalibrationTelemetryStore(defaults: try makeDefaults())
        store.recordRoundOutcome(
            context: Self.sampleContext(),
            roundDurationSeconds: 60,
            finishReason: .timerExpired,
            revealedAnswerIndices: [0, 1, 4],
            totalAnswers: 10,
            pointsAwarded: 7,
            remainingTimeAtFinish: 0,
            timeToFirstReveal: 1.2
        )
        let transport = RecordingQuestionCalibrationTransport()
        let endpoint = URL(string: "https://example.com/calibration")!
        let service = QuestionCalibrationSubmissionService(
            transport: transport,
            store: store,
            endpointProvider: { endpoint }
        )

        let status = await service.submitPendingEventsIfPossible()

        #expect(status == .sent)
        #expect(await service.pendingEventCount() == 0)
        let requests = await transport.requests
        #expect(requests.count == 1)
        #expect(requests.first?.endpoint == endpoint)
        #expect(requests.first?.events.count == 1)
        #expect(requests.first?.events.first?.questionID == "question-1")
    }

    @Test
    func failedSubmissionKeepsPendingEventsForRetry() async throws {
        let store = QuestionCalibrationTelemetryStore(defaults: try makeDefaults())
        store.recordRoundOutcome(
            context: Self.sampleContext(),
            roundDurationSeconds: 60,
            finishReason: .skipped,
            revealedAnswerIndices: [0],
            totalAnswers: 10,
            pointsAwarded: 1,
            remainingTimeAtFinish: 45,
            timeToFirstReveal: 3.0
        )
        let service = QuestionCalibrationSubmissionService(
            transport: FailingQuestionCalibrationTransport(),
            store: store,
            endpointProvider: { URL(string: "https://example.com/calibration") }
        )

        let status = await service.submitPendingEventsIfPossible()

        #expect(status == .savedForRetry)
        #expect(await service.pendingEventCount() == 1)
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "QuestionCalibrationSubmissionServiceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    static func sampleContext() -> QuestionFeedbackContext {
        QuestionFeedbackContext(
            packID: "pack-id",
            packTitle: "Sample Pack",
            packVersion: "1.2",
            questionID: "question-1",
            prompt: "Name a fruit",
            category: "Food & Drink",
            difficultyTier: .medium,
            validationStyle: .editorial,
            sourceURL: URL(string: "https://example.com/fruit")!
        )
    }
}

private actor RecordingQuestionCalibrationTransport: QuestionCalibrationTransport {
    struct Request: Equatable, Sendable {
        let events: [QuestionCalibrationTelemetryEvent]
        let endpoint: URL
    }

    private(set) var requests: [Request] = []

    func send(_ events: [QuestionCalibrationTelemetryEvent], to endpoint: URL) async throws {
        requests.append(Request(events: events, endpoint: endpoint))
    }
}

private struct FailingQuestionCalibrationTransport: QuestionCalibrationTransport {
    func send(_ events: [QuestionCalibrationTelemetryEvent], to endpoint: URL) async throws {
        throw URLError(.notConnectedToInternet)
    }
}
