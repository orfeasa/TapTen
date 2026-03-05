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
}
