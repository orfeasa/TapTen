import Foundation

struct CategoryCatalogService {
    func categories() -> [GameCategory] {
        [
            GameCategory(name: "Geography"),
            GameCategory(name: "History"),
            GameCategory(name: "Science"),
            GameCategory(name: "Food & Drink"),
            GameCategory(name: "Film & TV"),
            GameCategory(name: "Everyday Life")
        ]
    }
}
