import Foundation
import Observation

@Observable
final class NewGameViewModel {
    var settings: GameSettings
    var categories: [GameCategory]
    var includedCategoryIDs: Set<GameCategory.ID>
    var includedDifficultyTiers: Set<QuestionDifficulty>
    private var suggestedTeamNamePairIndex = 0

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

    var hasSuggestedTeamNames: Bool {
        !Self.suggestedTeamNamePairs.isEmpty
    }

    func applyNextSuggestedTeamNames() {
        let pairs = Self.suggestedTeamNamePairs
        guard !pairs.isEmpty else {
            return
        }

        let currentTeamAName = trimmedTeamAName
        let currentTeamBName = trimmedTeamBName

        for _ in 0..<pairs.count {
            let pair = pairs[suggestedTeamNamePairIndex]
            suggestedTeamNamePairIndex = (suggestedTeamNamePairIndex + 1) % pairs.count

            let matchesCurrentNames =
                pair.teamA.caseInsensitiveCompare(currentTeamAName) == .orderedSame
                && pair.teamB.caseInsensitiveCompare(currentTeamBName) == .orderedSame

            if !matchesCurrentNames {
                settings.teamAName = pair.teamA
                settings.teamBName = pair.teamB
                return
            }
        }
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

private extension NewGameViewModel {
    struct TeamNamePair {
        let teamA: String
        let teamB: String
    }

    static let suggestedTeamNamePairs: [TeamNamePair] = [
        TeamNamePair(teamA: "Hot Takes", teamB: "Cold Pizza"),
        TeamNamePair(teamA: "Snack Attack", teamB: "Sip Happens"),
        TeamNamePair(teamA: "Mildly Iconic", teamB: "Barely Ready"),
        TeamNamePair(teamA: "Peak Chaos", teamB: "Soft Launch"),
        TeamNamePair(teamA: "Big Guesses", teamB: "Bold Claims"),
        TeamNamePair(teamA: "No Notes", teamB: "Some Notes"),
        TeamNamePair(teamA: "Brain Cell A", teamB: "Brain Cell B"),
        TeamNamePair(teamA: "Fast & Curious", teamB: "Loose Cannons"),
        TeamNamePair(teamA: "Lucky Ducks", teamB: "Quick Quips"),
        TeamNamePair(teamA: "Sharp Elbows", teamB: "Clean Slate")
    ]
}
