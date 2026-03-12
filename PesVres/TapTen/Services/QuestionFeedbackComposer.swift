import Foundation

struct QuestionFeedbackContext: Equatable, Sendable {
    let packID: String?
    let packTitle: String?
    let packVersion: String?
    let questionID: String
    let prompt: String
    let category: String
    let difficultyTier: QuestionDifficulty
    let validationStyle: ValidationStyle
    let sourceURL: URL
}

enum QuestionFeedbackReason: String, CaseIterable, Identifiable, Sendable {
    case incorrectAnswers
    case unclearPrompt
    case outdatedSource
    case duplicateQuestion
    case notFun
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .incorrectAnswers:
            return "Incorrect answers"
        case .unclearPrompt:
            return "Unclear prompt"
        case .outdatedSource:
            return "Outdated source"
        case .duplicateQuestion:
            return "Duplicate question"
        case .notFun:
            return "Not fun"
        case .other:
            return "Other"
        }
    }
}

struct QuestionFeedbackComposer {
    // Replace with the real feedback inbox before external release.
    static let feedbackRecipient = "feedback@tapten.app"

    let context: QuestionFeedbackContext
    let reason: QuestionFeedbackReason
    let note: String
    let appVersion: String

    init(
        context: QuestionFeedbackContext,
        reason: QuestionFeedbackReason,
        note: String,
        bundle: Bundle = .main
    ) {
        self.context = context
        self.reason = reason
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.appVersion = Self.versionString(bundle: bundle)
    }

    var subject: String {
        "Tap Ten feedback: \(context.questionID)"
    }

    var body: String {
        let lines = [
            "Tap Ten Question Feedback",
            "",
            "Reason: \(reason.title)",
            "Question ID: \(context.questionID)",
            "Prompt: \(context.prompt)",
            "Category: \(context.category)",
            "Difficulty Tier: \(context.difficultyTier.rawValue)",
            "Validation Style: \(context.validationStyle.rawValue)",
            "Pack Title: \(context.packTitle ?? "Unknown")",
            "Pack ID: \(context.packID ?? "Unknown")",
            "Pack Version: \(context.packVersion ?? "Unknown")",
            "Source URL: \(context.sourceURL.absoluteString)",
            "App Version: \(appVersion)",
            "",
            "Notes:",
            note.isEmpty ? "No extra notes provided." : note
        ]

        return lines.joined(separator: "\n")
    }

    var emailURL: URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = Self.feedbackRecipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }
}

private extension QuestionFeedbackComposer {
    static func versionString(bundle: Bundle) -> String {
        let shortVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let buildNumber = bundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String

        switch (shortVersion, buildNumber) {
        case let (version?, build?) where !version.isEmpty && !build.isEmpty:
            return "\(version) (\(build))"
        case let (version?, _):
            return version
        case let (_, build?):
            return build
        default:
            return "Unknown"
        }
    }
}
