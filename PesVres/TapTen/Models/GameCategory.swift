import Foundation

struct GameCategory: Identifiable, Equatable {
    let id: String
    let name: String

    init(id: String? = nil, name: String) {
        let normalizedName = name
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(
                of: "[^a-z0-9]+",
                with: "-",
                options: .regularExpression
            )
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        self.id = id ?? normalizedName
        self.name = name
    }
}
