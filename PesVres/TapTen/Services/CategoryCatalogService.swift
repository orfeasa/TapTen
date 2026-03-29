import Foundation

struct CategoryCatalogService {
    private let questionPackLoader: QuestionPackLoader
    private let entitlementStore: QuestionPackEntitlementStore

    init(
        questionPackLoader: QuestionPackLoader = QuestionPackLoader(),
        entitlementStore: QuestionPackEntitlementStore = .shared
    ) {
        self.questionPackLoader = questionPackLoader
        self.entitlementStore = entitlementStore
    }

    func categories() -> [GameCategory] {
        resolvedCategoryNames().map { GameCategory(name: $0) }
    }
}

extension CategoryCatalogService {
    static let starterCategoryNames = [
        "Everyday Life",
        "Food & Drink",
        "Film & TV",
        "Music",
        "Sport",
        "Geography",
        "History",
        "Science",
        "Technology",
        "Travel",
        "Work & School",
        "Pop Culture & Trends"
    ]
}

private extension CategoryCatalogService {
    func resolvedCategoryNames() -> [String] {
        guard let availableCategoryNames = try? availableCategoryNames(),
              !availableCategoryNames.isEmpty else {
            return Self.starterCategoryNames
        }

        return availableCategoryNames
    }

    func availableCategoryNames() throws -> [String] {
        let packs = try questionPackLoader.loadAllPacks()
        let accessiblePacks = entitlementStore.accessiblePacks(from: packs)

        let categoryNames = Set(
            accessiblePacks
                .flatMap(\.questions)
                .map(\.category)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )

        return orderedCategoryNames(from: categoryNames)
    }

    func orderedCategoryNames(from availableCategoryNames: Set<String>) -> [String] {
        let starterCategorySet = Set(Self.starterCategoryNames)
        let starterCategories = Self.starterCategoryNames.filter { availableCategoryNames.contains($0) }
        let additionalCategories = availableCategoryNames
            .subtracting(starterCategorySet)
            .sorted()

        return starterCategories + additionalCategories
    }
}
