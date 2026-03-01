import Foundation

struct Question: Equatable, Codable, Sendable {
    let id: String
    let category: String
    let prompt: String
    let validationStyle: ValidationStyle
    let sourceURL: URL
    let answers: [AnswerOption]
}
