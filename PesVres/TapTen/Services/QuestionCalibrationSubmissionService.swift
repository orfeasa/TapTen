import Foundation

enum QuestionCalibrationSubmissionStatus: Equatable, Sendable {
    case sent
    case savedForRetry
    case savedPendingConfiguration
}

protocol QuestionCalibrationTransport: Sendable {
    nonisolated func send(
        _ events: [QuestionCalibrationTelemetryEvent],
        to endpoint: URL
    ) async throws
}

struct URLSessionQuestionCalibrationTransport: QuestionCalibrationTransport {
    var session: URLSession

    nonisolated init(session: URLSession = .shared) {
        self.session = session
    }

    nonisolated func send(
        _ events: [QuestionCalibrationTelemetryEvent],
        to endpoint: URL
    ) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try await MainActor.run {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(events)
        }

        let (_, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw QuestionFeedbackSubmissionError.invalidResponse
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            throw QuestionFeedbackSubmissionError.unsuccessfulStatusCode(httpResponse.statusCode)
        }
    }
}

actor QuestionCalibrationSubmissionService {
    @MainActor
    static let shared = QuestionCalibrationSubmissionService(
        transport: URLSessionQuestionCalibrationTransport(),
        store: .shared,
        endpointProvider: {
            MainActor.assumeIsolated {
                QuestionCalibrationConfiguration.endpointURL()
            }
        }
    )

    private let transport: any QuestionCalibrationTransport
    private let store: QuestionCalibrationTelemetryStore
    private let endpointProvider: @Sendable () -> URL?

    init(
        transport: any QuestionCalibrationTransport,
        store: QuestionCalibrationTelemetryStore,
        endpointProvider: @escaping @Sendable () -> URL?
    ) {
        self.transport = transport
        self.store = store
        self.endpointProvider = endpointProvider
    }

    func submitPendingEventsIfPossible() async -> QuestionCalibrationSubmissionStatus? {
        guard let endpoint = await currentEndpointURL() else {
            return await pendingEventCount() > 0 ? .savedPendingConfiguration : nil
        }

        let pendingEvents = await MainActor.run {
            store.pendingEvents()
        }
        guard !pendingEvents.isEmpty else {
            return nil
        }

        do {
            try await transport.send(pendingEvents, to: endpoint)
            await MainActor.run {
                store.removeEvents(withIDs: Set(pendingEvents.map(\.id)))
            }
            return .sent
        } catch {
            return .savedForRetry
        }
    }

    func pendingEventCount() async -> Int {
        await MainActor.run {
            store.pendingEvents().count
        }
    }

    private func currentEndpointURL() async -> URL? {
        await MainActor.run {
            endpointProvider()
        }
    }
}

enum QuestionCalibrationConfiguration {
    nonisolated static func endpointURL(
        bundle: Bundle = .main,
        processInfo: ProcessInfo = .processInfo
    ) -> URL? {
        if let rawValue = processInfo.environment["TAPTEN_CALIBRATION_ENDPOINT"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !rawValue.isEmpty,
           let url = URL(string: rawValue) {
            return url
        }

        if let rawValue = bundle.object(forInfoDictionaryKey: "QuestionCalibrationEndpointURL") as? String,
           !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let url = URL(string: rawValue) {
            return url
        }

        return nil
    }
}
