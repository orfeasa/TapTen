import Foundation

struct QuestionPack: Equatable, Codable, Sendable {
    let id: String
    let title: String
    let languageCode: String
    let questions: [Question]
}
