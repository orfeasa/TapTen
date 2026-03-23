import Foundation

struct QuestionFeedbackReport: Codable, Equatable, Identifiable, Sendable {
    let id: UUID
    let submittedAt: Date
    let reason: QuestionFeedbackReason
    let note: String
    let appVersion: String
    let packID: String?
    let packTitle: String?
    let packVersion: String?
    let questionID: String
    let prompt: String
    let category: String
    let difficultyTier: QuestionDifficulty
    let validationStyle: ValidationStyle
    let sourceURL: URL

    init(
        id: UUID = UUID(),
        submittedAt: Date = Date(),
        context: QuestionFeedbackContext,
        reason: QuestionFeedbackReason,
        note: String,
        appVersion: String
    ) {
        self.id = id
        self.submittedAt = submittedAt
        self.reason = reason
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.appVersion = appVersion
        self.packID = context.packID
        self.packTitle = context.packTitle
        self.packVersion = context.packVersion
        self.questionID = context.questionID
        self.prompt = context.prompt
        self.category = context.category
        self.difficultyTier = context.difficultyTier
        self.validationStyle = context.validationStyle
        self.sourceURL = context.sourceURL
    }
}

enum QuestionFeedbackSubmissionStatus: Equatable, Sendable {
    case sent
    case savedForRetry
    case savedPendingConfiguration

    var title: String {
        switch self {
        case .sent:
            return "Report sent"
        case .savedForRetry, .savedPendingConfiguration:
            return "Report saved"
        }
    }

    var message: String {
        switch self {
        case .sent:
            return "Thanks. The question report was sent successfully."
        case .savedForRetry:
            return "The report was saved on this device and will retry automatically when the app is active again."
        case .savedPendingConfiguration:
            return "The report was saved on this device. Delivery will start automatically once reporting is configured for this build."
        }
    }
}

protocol QuestionFeedbackTransport: Sendable {
    nonisolated func send(_ report: QuestionFeedbackReport, to endpoint: URL) async throws
}

struct URLSessionQuestionFeedbackTransport: QuestionFeedbackTransport {
    var session: URLSession

    nonisolated init(session: URLSession = .shared) {
        self.session = session
    }

    nonisolated func send(_ report: QuestionFeedbackReport, to endpoint: URL) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try await MainActor.run {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(report)
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

actor QuestionFeedbackSubmissionService {
    @MainActor
    static let shared = QuestionFeedbackSubmissionService(
        transport: URLSessionQuestionFeedbackTransport(),
        store: .shared,
        endpointProvider: {
            MainActor.assumeIsolated {
                QuestionFeedbackConfiguration.endpointURL()
            }
        }
    )

    private let transport: any QuestionFeedbackTransport
    private let store: QuestionFeedbackQueueStore
    private let endpointProvider: @Sendable () -> URL?

    init(
        transport: any QuestionFeedbackTransport,
        store: QuestionFeedbackQueueStore,
        endpointProvider: @escaping @Sendable () -> URL?
    ) {
        self.transport = transport
        self.store = store
        self.endpointProvider = endpointProvider
    }

    func submit(_ report: QuestionFeedbackReport) async -> QuestionFeedbackSubmissionStatus {
        guard let endpoint = await currentEndpointURL() else {
            await MainActor.run {
                store.enqueue(report)
            }
            return .savedPendingConfiguration
        }

        do {
            try await transport.send(report, to: endpoint)
            await flushPendingReportsIfPossible()
            return .sent
        } catch {
            await MainActor.run {
                store.enqueue(report)
            }
            return .savedForRetry
        }
    }

    func flushPendingReportsIfPossible() async {
        guard let endpoint = await currentEndpointURL() else {
            return
        }

        let pendingReports = await MainActor.run {
            store.pendingReports()
        }
        guard !pendingReports.isEmpty else {
            return
        }

        var failedIndex: Int?

        for (index, report) in pendingReports.enumerated() {
            do {
                try await transport.send(report, to: endpoint)
            } catch {
                failedIndex = index
                break
            }
        }

        if let failedIndex {
            await MainActor.run {
                store.replaceQueue(with: Array(pendingReports.dropFirst(failedIndex)))
            }
        } else {
            await MainActor.run {
                store.replaceQueue(with: [])
            }
        }
    }

    func pendingReportCount() async -> Int {
        await MainActor.run {
            store.pendingReports().count
        }
    }

    private func currentEndpointURL() async -> URL? {
        await MainActor.run {
            endpointProvider()
        }
    }
}

final class QuestionFeedbackQueueStore: @unchecked Sendable {
    static let shared = QuestionFeedbackQueueStore()

    private let defaults: UserDefaults
    private let queueKey = "pendingQuestionFeedbackReports"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func pendingReports() -> [QuestionFeedbackReport] {
        guard let data = defaults.data(forKey: queueKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([QuestionFeedbackReport].self, from: data)
        } catch {
            return []
        }
    }

    func enqueue(_ report: QuestionFeedbackReport) {
        var queue = pendingReports()
        queue.append(report)
        replaceQueue(with: queue)
    }

    func replaceQueue(with reports: [QuestionFeedbackReport]) {
        if reports.isEmpty {
            defaults.removeObject(forKey: queueKey)
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(reports)
            defaults.set(data, forKey: queueKey)
        } catch {
            defaults.removeObject(forKey: queueKey)
        }
    }
}

enum QuestionFeedbackSubmissionError: Error {
    case invalidResponse
    case unsuccessfulStatusCode(Int)
}

enum QuestionFeedbackConfiguration {
    nonisolated static func endpointURL(
        bundle: Bundle = .main,
        processInfo: ProcessInfo = .processInfo
    ) -> URL? {
        if let rawValue = processInfo.environment["TAPTEN_FEEDBACK_ENDPOINT"]?.trimmingCharacters(in: .whitespacesAndNewlines),
           !rawValue.isEmpty,
           let url = URL(string: rawValue) {
            return url
        }

        if let rawValue = bundle.object(forInfoDictionaryKey: "QuestionFeedbackEndpointURL") as? String,
           !rawValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let url = URL(string: rawValue) {
            return url
        }

        return nil
    }
}
