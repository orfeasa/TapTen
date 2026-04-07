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

enum QuestionFeedbackReason: String, Codable, CaseIterable, Identifiable, Sendable {
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
}

struct QuestionFeedbackComposer {
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

    var report: QuestionFeedbackReport {
        QuestionFeedbackReport(
            context: context,
            reason: reason,
            note: note,
            appVersion: appVersion
        )
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
