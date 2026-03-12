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
    case tooEasy
    case tooDifficult
    case wrongCategory
    case inappropriate
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .tooEasy:
            return "Too easy"
        case .tooDifficult:
            return "Too difficult"
        case .wrongCategory:
            return "Wrong category"
        case .inappropriate:
            return "Inappropriate"
        case .other:
            return "Other"
        }
    }

    var detail: String {
        switch self {
        case .tooEasy:
            return "The question feels easier than its current difficulty suggests."
        case .tooDifficult:
            return "The question feels too hard for the current pack or tier."
        case .wrongCategory:
            return "The prompt looks like it belongs in a different category."
        case .inappropriate:
            return "The question may be unsuitable for the app's tone or audience."
        case .other:
            return "Something else is off. Add details so it can be reviewed properly."
        }
    }

    var subjectLinePrefix: String {
        switch self {
        case .tooEasy:
            return "Too Easy"
        case .tooDifficult:
            return "Too Difficult"
        case .wrongCategory:
            return "Wrong Category"
        case .inappropriate:
            return "Inappropriate"
        case .other:
            return "Other Report"
        }
    }

    var reviewRequest: String {
        switch self {
        case .tooEasy:
            return "Review difficulty calibration. This question may be too easy for its current tier."
        case .tooDifficult:
            return "Review difficulty calibration. This question may be too difficult for its current tier."
        case .wrongCategory:
            return "Review category placement. This question may belong in a different category."
        case .inappropriate:
            return "Review tone and suitability. This question may be inappropriate for the app."
        case .other:
            return "Review editorial fit based on the notes below."
        }
    }
}

struct QuestionFeedbackComposer {
    static let feedbackRecipient = "tapten-reports@orfeasa.com"

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
        "Tap Ten Report: \(reason.subjectLinePrefix) [\(context.questionID)]"
    }

    var body: String {
        let lines = [
            "Tap Ten Question Report",
            "",
            "Report Type: \(reason.title)",
            "Review Request: \(reason.reviewRequest)",
            "Question ID: \(context.questionID)",
            "Prompt: \(context.prompt)",
            "Category: \(context.category)",
            "Difficulty Tier: \(context.difficultyTier.rawValue.capitalized)",
            "Validation Style: \(context.validationStyle.rawValue)",
            "Pack Title: \(context.packTitle ?? "Unknown")",
            "Pack ID: \(context.packID ?? "Unknown")",
            "Pack Version: \(context.packVersion ?? "Unknown")",
            "Source URL: \(context.sourceURL.absoluteString)",
            "App Version: \(appVersion)",
            "",
            "Reporter Notes:",
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
