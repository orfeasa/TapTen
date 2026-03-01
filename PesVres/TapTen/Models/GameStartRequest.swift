import Foundation

struct GameStartRequest: Identifiable, Equatable, Hashable {
    let id = UUID()
    let settings: GameSettings
    let enabledCategoryNames: Set<String>
}
