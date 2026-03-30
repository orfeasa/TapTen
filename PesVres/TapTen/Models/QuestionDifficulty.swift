import Foundation

enum QuestionDifficulty: String, Codable, CaseIterable, Sendable {
    case easy
    case medium
    case hard
}

extension QuestionDifficulty {
    static func tier(forScore score: Int) -> QuestionDifficulty? {
        switch score {
        case 12...18:
            return .easy
        case 19...26:
            return .medium
        case 27...35:
            return .hard
        default:
            return nil
        }
    }
}
