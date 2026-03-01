import Foundation

struct GameCategory: Identifiable, Equatable {
    let id: UUID
    let name: String

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name
    }
}
