import Foundation

struct Question: Equatable, Codable, Sendable {
    let id: String
    let category: String
    let prompt: String
    let difficultyTier: QuestionDifficulty
    let difficultyScore: Int
    let validationStyle: ValidationStyle
    let sourceURL: URL
    let answers: [AnswerOption]
    let contentType: String?
    let quality: String?
    let tags: [String]?
    let difficultyNotes: String?
    let editorialNotes: String?

    // Backward-compatible alias for existing call sites.
    var difficulty: QuestionDifficulty {
        difficultyTier
    }

    init(
        id: String,
        category: String,
        prompt: String,
        difficultyTier: QuestionDifficulty,
        difficultyScore: Int,
        validationStyle: ValidationStyle,
        sourceURL: URL,
        answers: [AnswerOption],
        contentType: String? = nil,
        quality: String? = nil,
        tags: [String]? = nil,
        difficultyNotes: String? = nil,
        editorialNotes: String? = nil
    ) {
        self.id = id
        self.category = category
        self.prompt = prompt
        self.difficultyTier = difficultyTier
        self.difficultyScore = difficultyScore
        self.validationStyle = validationStyle
        self.sourceURL = sourceURL
        self.answers = answers
        self.contentType = contentType
        self.quality = quality
        self.tags = tags
        self.difficultyNotes = difficultyNotes
        self.editorialNotes = editorialNotes
    }

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
        tags: [String]? = nil,
        difficultyNotes: String? = nil,
        editorialNotes: String? = nil
    ) {
        self.init(
            id: id,
            category: category,
            prompt: prompt,
            difficultyTier: difficulty,
            difficultyScore: answers.reduce(0) { $0 + $1.points },
            validationStyle: validationStyle,
            sourceURL: sourceURL,
            answers: answers,
            contentType: contentType,
            quality: quality,
            tags: tags,
            difficultyNotes: difficultyNotes,
            editorialNotes: editorialNotes
        )
    }
}
