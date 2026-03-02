import Foundation

struct Question: Equatable, Codable, Sendable {
    let id: String
    let category: String
    let prompt: String
    let difficulty: QuestionDifficulty
    let validationStyle: ValidationStyle
    let sourceURL: URL
    let answers: [AnswerOption]
    let contentType: String?
    let quality: String?
    let difficultyNotes: String?
    let editorialNotes: String?

    init(
        id: String,
        category: String,
        prompt: String,
        difficulty: QuestionDifficulty,
        validationStyle: ValidationStyle,
        sourceURL: URL,
        answers: [AnswerOption],
        contentType: String? = nil,
        quality: String? = nil,
        difficultyNotes: String? = nil,
        editorialNotes: String? = nil
    ) {
        self.id = id
        self.category = category
        self.prompt = prompt
        self.difficulty = difficulty
        self.validationStyle = validationStyle
        self.sourceURL = sourceURL
        self.answers = answers
        self.contentType = contentType
        self.quality = quality
        self.difficultyNotes = difficultyNotes
        self.editorialNotes = editorialNotes
    }
}
