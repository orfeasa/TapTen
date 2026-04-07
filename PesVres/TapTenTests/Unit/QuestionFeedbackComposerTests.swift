import Foundation
import Testing
@testable import TapTen

struct QuestionFeedbackComposerTests {
    @Test
    func reportTrimsNotesAndCarriesStructuredQuestionMetadata() {
        let composer = QuestionFeedbackComposer(
            context: QuestionFeedbackContext(
                packID: "pack-id",
                packTitle: "Sample Pack",
                packVersion: "2.0",
                questionID: "question-1",
                prompt: "Name a fruit",
                category: "Food & Drink",
                difficultyTier: .easy,
                validationStyle: .factual,
                sourceURL: URL(string: "https://example.com/source")!
            ),
            reason: .tooDifficult,
            note: "  Most teams get stuck immediately.  "
        )

        let report = composer.report
        #expect(report.reason == .tooDifficult)
        #expect(report.note == "Most teams get stuck immediately.")
        #expect(report.questionID == "question-1")
        #expect(report.packTitle == "Sample Pack")
        #expect(report.category == "Food & Drink")
        #expect(report.sourceURL == URL(string: "https://example.com/source")!)
    }

    @Test
    func reportIncludesRequiredStructuredFields() {
        let composer = QuestionFeedbackComposer(
            context: QuestionFeedbackContext(
                packID: "pack-id",
                packTitle: "Sample Pack",
                packVersion: nil,
                questionID: "question-2",
                prompt: "Name a city",
                category: "Geography",
                difficultyTier: .medium,
                validationStyle: .editorial,
                sourceURL: URL(string: "https://example.com/city")!
            ),
            reason: .wrongCategory,
            note: ""
        )

        let report = composer.report
        #expect(report.reason == .wrongCategory)
        #expect(report.questionID == "question-2")
        #expect(report.category == "Geography")
        #expect(report.difficultyTier == .medium)
        #expect(report.validationStyle == .editorial)
        #expect(report.packVersion == nil)
        #expect(report.sourceURL == URL(string: "https://example.com/city")!)
    }
}
