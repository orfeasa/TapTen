import Foundation
import Observation

@Observable
final class NewGameViewModel {
    var settings: GameSettings
    var categories: [GameCategory]
    var includedCategoryIDs: Set<GameCategory.ID>
    var showStartConfirmation = false

    init(
        settings: GameSettings = GameSettings(),
        categoryService: CategoryCatalogService = CategoryCatalogService()
    ) {
        let loadedCategories = categoryService.categories()
        self.settings = settings
        self.categories = loadedCategories
        self.includedCategoryIDs = Set(loadedCategories.map(\.id))
    }

    var includedCategoryCount: Int {
        includedCategoryIDs.count
    }

    var trimmedTeamAName: String {
        settings.teamAName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var trimmedTeamBName: String {
        settings.teamBName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var teamNamesAreValid: Bool {
        !trimmedTeamAName.isEmpty
        && !trimmedTeamBName.isEmpty
        && trimmedTeamAName.caseInsensitiveCompare(trimmedTeamBName) != .orderedSame
    }

    var categoriesAreValid: Bool {
        !includedCategoryIDs.isEmpty
    }

    var canStartGame: Bool {
        teamNamesAreValid && categoriesAreValid
    }

    var validationMessage: String? {
        if trimmedTeamAName.isEmpty || trimmedTeamBName.isEmpty {
            return "Both team names are required."
        }

        if trimmedTeamAName.caseInsensitiveCompare(trimmedTeamBName) == .orderedSame {
            return "Team names must be different."
        }

        if includedCategoryIDs.isEmpty {
            return "Select at least one category."
        }

        return nil
    }

    func isCategoryIncluded(_ category: GameCategory) -> Bool {
        includedCategoryIDs.contains(category.id)
    }

    func setCategory(_ category: GameCategory, included: Bool) {
        if included {
            includedCategoryIDs.insert(category.id)
        } else {
            includedCategoryIDs.remove(category.id)
        }
    }

    func includeAllCategories() {
        includedCategoryIDs = Set(categories.map(\.id))
    }

    func excludeAllCategories() {
        includedCategoryIDs.removeAll()
    }

    func startGame() {
        guard canStartGame else {
            return
        }

        settings.teamAName = trimmedTeamAName
        settings.teamBName = trimmedTeamBName
        showStartConfirmation = true
    }
}
