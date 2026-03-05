import Foundation
import Observation

@Observable
final class NewGameViewModel {
    var settings: GameSettings
    var categories: [GameCategory]
    var includedCategoryIDs: Set<GameCategory.ID>
    var includedDifficultyTiers: Set<QuestionDifficulty>

    init(
        settings: GameSettings = GameSettings(),
        categoryService: CategoryCatalogService = CategoryCatalogService()
    ) {
        let loadedCategories = categoryService.categories()
        self.settings = settings
        self.categories = loadedCategories
        self.includedCategoryIDs = Set(loadedCategories.map(\.id))
        self.includedDifficultyTiers = Set(QuestionDifficulty.allCases)
    }

    var includedCategoryCount: Int {
        includedCategoryIDs.count
    }

    var includedCategoryNames: Set<String> {
        Set(
            categories
                .filter { includedCategoryIDs.contains($0.id) }
                .map(\.name)
        )
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
        teamNamesAreValid && categoriesAreValid && difficultiesAreValid
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

        if includedDifficultyTiers.isEmpty {
            return "Select at least one difficulty tier."
        }

        return nil
    }

    var difficultiesAreValid: Bool {
        !includedDifficultyTiers.isEmpty
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

    func isDifficultyIncluded(_ difficulty: QuestionDifficulty) -> Bool {
        includedDifficultyTiers.contains(difficulty)
    }

    func setDifficulty(_ difficulty: QuestionDifficulty, included: Bool) {
        if included {
            includedDifficultyTiers.insert(difficulty)
        } else {
            includedDifficultyTiers.remove(difficulty)
        }
    }

    func includeAllDifficulties() {
        includedDifficultyTiers = Set(QuestionDifficulty.allCases)
    }

    func excludeAllDifficulties() {
        includedDifficultyTiers.removeAll()
    }

    @discardableResult
    func startGame() -> Bool {
        guard canStartGame else {
            return false
        }

        settings.teamAName = trimmedTeamAName
        settings.teamBName = trimmedTeamBName
        return true
    }
}
