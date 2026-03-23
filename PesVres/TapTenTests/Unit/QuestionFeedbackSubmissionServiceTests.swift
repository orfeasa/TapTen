import Foundation
import Testing
@testable import TapTen

struct QuestionFeedbackSubmissionServiceTests {
    @Test
    func submitQueuesReportWhenEndpointIsUnavailable() async {
        let defaults = makeDefaults()
        let store = QuestionFeedbackQueueStore(defaults: defaults)
        let service = QuestionFeedbackSubmissionService(
            transport: RecordingQuestionFeedbackTransport(),
            store: store,
            endpointProvider: { nil }
        )

        let status = await service.submit(Self.sampleReport())

        #expect(status == .savedPendingConfiguration)
        #expect(await service.pendingReportCount() == 1)
    }

    @Test
    func submitSendsImmediatelyWhenEndpointIsConfigured() async {
        let defaults = makeDefaults()
        let store = QuestionFeedbackQueueStore(defaults: defaults)
        let transport = RecordingQuestionFeedbackTransport()
        let endpoint = URL(string: "https://example.com/reports")!
        let service = QuestionFeedbackSubmissionService(
            transport: transport,
            store: store,
            endpointProvider: { endpoint }
        )

        let status = await service.submit(Self.sampleReport())

        #expect(status == .sent)
        #expect(await service.pendingReportCount() == 0)
        let requests = await transport.requests
        #expect(requests.count == 1)
        #expect(requests.first?.endpoint == endpoint)
        #expect(requests.first?.report.questionID == "question-1")
    }

    @Test
    func failedSubmissionQueuesReportAndFlushRetriesLater() async {
        let defaults = makeDefaults()
        let store = QuestionFeedbackQueueStore(defaults: defaults)
        let endpoint = URL(string: "https://example.com/reports")!

        let failingService = QuestionFeedbackSubmissionService(
            transport: FailingQuestionFeedbackTransport(),
            store: store,
            endpointProvider: { endpoint }
        )

        let failedStatus = await failingService.submit(Self.sampleReport())
        #expect(failedStatus == .savedForRetry)
        #expect(await failingService.pendingReportCount() == 1)

        let recoveryTransport = RecordingQuestionFeedbackTransport()
        let recoveringService = QuestionFeedbackSubmissionService(
            transport: recoveryTransport,
            store: store,
            endpointProvider: { endpoint }
        )

        await recoveringService.flushPendingReportsIfPossible()

        #expect(await recoveringService.pendingReportCount() == 0)
        let requests = await recoveryTransport.requests
        #expect(requests.count == 1)
        #expect(requests.first?.report.questionID == "question-1")
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "QuestionFeedbackSubmissionServiceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }

    static func sampleReport() -> QuestionFeedbackReport {
        QuestionFeedbackReport(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
            submittedAt: Date(timeIntervalSince1970: 1_700_000_000),
            context: QuestionFeedbackContext(
                packID: "pack-id",
                packTitle: "Sample Pack",
                packVersion: "1.2",
                questionID: "question-1",
                prompt: "Name a fruit",
                category: "Food & Drink",
                difficultyTier: .medium,
                validationStyle: .editorial,
                sourceURL: URL(string: "https://example.com/fruit")!
            ),
            reason: .tooEasy,
            note: "Teams usually clear it instantly.",
            appVersion: "1.0 (1)"
        )
    }
}

private actor RecordingQuestionFeedbackTransport: QuestionFeedbackTransport {
    struct Request: Equatable, Sendable {
        let report: QuestionFeedbackReport
        let endpoint: URL
    }

    private(set) var requests: [Request] = []

    func send(_ report: QuestionFeedbackReport, to endpoint: URL) async throws {
        requests.append(Request(report: report, endpoint: endpoint))
    }
}

private struct FailingQuestionFeedbackTransport: QuestionFeedbackTransport {
    func send(_ report: QuestionFeedbackReport, to endpoint: URL) async throws {
        throw URLError(.notConnectedToInternet)
    }
}
