import Foundation

struct QuestionPack: Equatable, Codable, Sendable {
    let id: String
    let title: String
    let languageCode: String
    let questions: [Question]
    let packVersion: String?

    init(
        id: String,
        title: String,
        languageCode: String,
        questions: [Question],
        packVersion: String? = nil
    ) {
        self.id = id
        self.title = title
        self.languageCode = languageCode
        self.questions = questions
        self.packVersion = packVersion
    }
}
