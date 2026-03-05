import Foundation

struct CategoryCatalogService {
    func categories() -> [GameCategory] {
        [
            GameCategory(name: "Everyday Life"),
            GameCategory(name: "Food & Drink"),
            GameCategory(name: "Film & TV"),
            GameCategory(name: "Music"),
            GameCategory(name: "Sport"),
            GameCategory(name: "Geography"),
            GameCategory(name: "History"),
            GameCategory(name: "Science"),
            GameCategory(name: "Technology"),
            GameCategory(name: "Travel"),
            GameCategory(name: "Work & School"),
            GameCategory(name: "Pop Culture & Trends")
        ]
    }
}
