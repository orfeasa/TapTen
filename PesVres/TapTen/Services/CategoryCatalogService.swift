import Foundation

struct CategoryCatalogService {
    func categories() -> [GameCategory] {
        [
            GameCategory(name: "Factual"),
            GameCategory(name: "Editorial"),
            GameCategory(name: "Humorous"),
            GameCategory(name: "Pop Culture"),
            GameCategory(name: "Food")
        ]
    }
}
