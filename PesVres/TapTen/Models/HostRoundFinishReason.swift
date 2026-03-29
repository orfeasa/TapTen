import Foundation

enum HostRoundFinishReason: String, Codable, Equatable, Sendable {
    case timerExpired
    case skipped
}
