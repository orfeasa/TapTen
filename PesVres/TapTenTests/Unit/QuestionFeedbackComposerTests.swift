import Foundation
import Testing
@testable import TapTen

struct QuestionFeedbackComposerTests {
    @Test
    func bodyIncludesRequiredStructuredMetadata() {
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
            reason: .unclearPrompt,
            note: "Too broad."
        )

        #expect(composer.body.contains("Reason: Unclear prompt"))
        #expect(composer.body.contains("Question ID: question-1"))
        #expect(composer.body.contains("Pack Title: Sample Pack"))
        #expect(composer.body.contains("Source URL: https://example.com/source"))
        #expect(composer.body.contains("Notes:\nToo broad."))
    }

    @Test
    func emailURLIncludesSubjectAndBody() throws {
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
            reason: .duplicateQuestion,
            note: ""
        )

        let emailURL = try #require(composer.emailURL)
        let absolute = emailURL.absoluteString
        #expect(absolute.contains("mailto:feedback@tapten.app"))
        #expect(absolute.contains("subject=Tap%20Ten%20feedback:%20question-2"))
        #expect(absolute.contains("body="))
    }
}
