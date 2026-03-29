import Testing
@testable import TapTen

struct NewGameViewModelTests {
    @Test
    func defaultCategoryCatalogExposesFinalTwelveCategories() {
        let viewModel = makeViewModel()

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
        let viewModel = makeViewModel()

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
        let viewModel = makeViewModel()

        #expect(viewModel.includedDifficultyTiers == Set(QuestionDifficulty.allCases))
        #expect(viewModel.difficultiesAreValid)
    }

    @Test
    func excludingAllDifficultiesInvalidatesStartReadiness() {
        let viewModel = makeViewModel()

        viewModel.excludeAllDifficulties()

        #expect(!viewModel.canStartGame)
        #expect(viewModel.validationMessage == "Select at least one difficulty tier.")
    }

    @Test
    func defaultSetupUsesSeededCuratedTeamNamePair() {
        let viewModel = makeViewModel(initialSuggestedTeamNamePairIndex: 0)

        #expect(viewModel.settings.teamAName == "Hot Takes")
        #expect(viewModel.settings.teamBName == "Cold Pizza")
    }

    @Test
    func applyingSuggestedTeamNamesAdvancesToNextPair() {
        let viewModel = makeViewModel(initialSuggestedTeamNamePairIndex: 0)

        viewModel.applyNextSuggestedTeamNames()

        #expect(viewModel.settings.teamAName == "Snack Attack")
        #expect(viewModel.settings.teamBName == "Sip Happens")
    }

    @Test
    func applyingSuggestedTeamNamesSkipsCurrentPair() {
        let viewModel = makeViewModel(initialSuggestedTeamNamePairIndex: 0)
        viewModel.settings.teamAName = "Hot Takes"
        viewModel.settings.teamBName = "Cold Pizza"

        viewModel.applyNextSuggestedTeamNames()

        #expect(viewModel.settings.teamAName == "Snack Attack")
        #expect(viewModel.settings.teamBName == "Sip Happens")
    }

    @Test
    func seededSuggestedPairIndexCanStartFromLaterPair() {
        let viewModel = makeViewModel(initialSuggestedTeamNamePairIndex: 3)

        #expect(viewModel.settings.teamAName == "Peak Chaos")
        #expect(viewModel.settings.teamBName == "Soft Launch")
    }

    @Test
    func customTeamNamesAreNotOverwrittenOnInit() {
        let viewModel = makeViewModel(
            settings: GameSettings(
                teamAName: "Custom A",
                teamBName: "Custom B",
                numberOfRounds: 5,
                roundDurationSeconds: 60
            )
        )

        #expect(viewModel.settings.teamAName == "Custom A")
        #expect(viewModel.settings.teamBName == "Custom B")
    }

    private func makeViewModel(
        settings: GameSettings = GameSettings(),
        initialSuggestedTeamNamePairIndex: Int? = nil
    ) -> NewGameViewModel {
        NewGameViewModel(
            settings: settings,
            categoryService: CategoryCatalogService(
                questionPackLoader: QuestionPackLoader(packFileURLs: [])
            ),
            initialSuggestedTeamNamePairIndex: initialSuggestedTeamNamePairIndex
        )
    }
}
