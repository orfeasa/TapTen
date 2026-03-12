import Foundation
import Testing
@testable import TapTen

struct QuestionFeedbackComposerTests {
    @Test
    func bodyIncludesStructuredMetadataAndReasonSpecificReviewRequest() {
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
            note: "Most teams get stuck immediately."
        )

        #expect(composer.body.contains("Report Type: Too difficult"))
        #expect(composer.body.contains("Review Request: Review difficulty calibration. This question may be too difficult for its current tier."))
        #expect(composer.body.contains("Question ID: question-1"))
        #expect(composer.body.contains("Category: Food & Drink"))
        #expect(composer.body.contains("Difficulty Tier: Easy"))
        #expect(composer.body.contains("Pack Title: Sample Pack"))
        #expect(composer.body.contains("Source URL: https://example.com/source"))
        #expect(composer.body.contains("Reporter Notes:\nMost teams get stuck immediately."))
    }

    @Test
    func emailURLIncludesRecipientReasonSpecificSubjectAndBody() throws {
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

        let emailURL = try #require(composer.emailURL)
        let absolute = emailURL.absoluteString
        #expect(absolute.contains("mailto:tapten-reports@orfeasa.com"))
        #expect(absolute.contains("subject=Tap%20Ten%20Report:%20Wrong%20Category%20%5Bquestion-2%5D"))
        #expect(absolute.contains("body="))
    }
}
