import Testing
@testable import TapTen

struct NewGameViewModelTests {
    @Test
    func defaultCategoryCatalogExposesFinalTwelveCategories() {
        let viewModel = NewGameViewModel()

        let categoryNames = viewModel.categories.map(\.name)
        #expect(categoryNames == [
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
        ])
        #expect(viewModel.categories.count == 12)
    }

    @Test
    func includeAllCategoriesSelectsEveryLoadedCategory() throws {
        let viewModel = NewGameViewModel()

        let firstCategory = try #require(viewModel.categories.first)
        viewModel.setCategory(firstCategory, included: false)

        viewModel.includeAllCategories()

        #expect(viewModel.includedCategoryCount == viewModel.categories.count)
        for category in viewModel.categories {
            #expect(viewModel.isCategoryIncluded(category))
        }
    }

    @Test
    func categoryIDIsStableForSameCategoryName() {
        let first = GameCategory(name: "Pop Culture")
        let second = GameCategory(name: "Pop Culture")

        #expect(first.id == second.id)
    }

    @Test
    func defaultDifficultyFilterIncludesAllTiers() {
        let viewModel = NewGameViewModel()

        #expect(viewModel.includedDifficultyTiers == Set(QuestionDifficulty.allCases))
        #expect(viewModel.difficultiesAreValid)
    }

    @Test
    func excludingAllDifficultiesInvalidatesStartReadiness() {
        let viewModel = NewGameViewModel()

        viewModel.excludeAllDifficulties()

        #expect(!viewModel.canStartGame)
        #expect(viewModel.validationMessage == "Select at least one difficulty tier.")
    }

    @Test
    func applyingSuggestedTeamNamesUsesFirstCuratedPair() {
        let viewModel = NewGameViewModel()

        viewModel.applyNextSuggestedTeamNames()

        #expect(viewModel.settings.teamAName == "Hot Takes")
        #expect(viewModel.settings.teamBName == "Cold Pizza")
    }

    @Test
    func applyingSuggestedTeamNamesAdvancesToNextPair() {
        let viewModel = NewGameViewModel()

        viewModel.applyNextSuggestedTeamNames()
        viewModel.applyNextSuggestedTeamNames()

        #expect(viewModel.settings.teamAName == "Snack Attack")
        #expect(viewModel.settings.teamBName == "Sip Happens")
    }

    @Test
    func applyingSuggestedTeamNamesSkipsCurrentPair() {
        let viewModel = NewGameViewModel()
        viewModel.settings.teamAName = "Hot Takes"
        viewModel.settings.teamBName = "Cold Pizza"

        viewModel.applyNextSuggestedTeamNames()

        #expect(viewModel.settings.teamAName == "Snack Attack")
        #expect(viewModel.settings.teamBName == "Sip Happens")
    }
}
