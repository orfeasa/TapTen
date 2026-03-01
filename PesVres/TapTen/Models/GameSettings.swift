import Foundation

struct GameSettings: Equatable, Hashable {
    var teamAName: String = "Team A"
    var teamBName: String = "Team B"
    var numberOfRounds: Int = 5
    var roundDurationSeconds: Int = 60
}
