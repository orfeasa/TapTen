import Foundation
import Observation

@Observable
final class NewGameViewModel {
    var settings: GameSettings
    var categories: [GameCategory]
    var includedCategoryIDs: Set<GameCategory.ID>
    var includedDifficultyTiers: Set<QuestionDifficulty>
    private let settingsStore: AppSettingsStore
    private var suggestedTeamNamePairIndex = 0
    private var teamANameSource: NewGameTeamNameSource = .manual
    private var teamBNameSource: NewGameTeamNameSource = .manual

    init(
        settings: GameSettings = GameSettings(),
        categoryService: CategoryCatalogService = CategoryCatalogService(),
        settingsStore: AppSettingsStore = .shared,
        initialSuggestedTeamNamePairIndex: Int? = nil
    ) {
        let loadedCategories = categoryService.categories()
        self.settings = settings
        self.categories = loadedCategories
        self.includedCategoryIDs = Set(loadedCategories.map(\.id))
        self.includedDifficultyTiers = Set(QuestionDifficulty.allCases)
        self.settingsStore = settingsStore
        restorePersistedTeamNamesIfNeeded(initialPairIndex: initialSuggestedTeamNamePairIndex)
        seedSuggestedTeamNamesIfNeeded(initialPairIndex: initialSuggestedTeamNamePairIndex)
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
                teamANameSource = .random
                teamBNameSource = .random
                updateTeamNames(teamA: pair.teamA, teamB: pair.teamB)
                persistTeamNameDraft()
                return
            }
        }
    }

    func setTeamAName(_ name: String) {
        teamANameSource = .manual
        updateTeamNames(teamA: name, teamB: settings.teamBName)
        persistTeamNameDraft()
    }

    func setTeamBName(_ name: String) {
        teamBNameSource = .manual
        updateTeamNames(teamA: settings.teamAName, teamB: name)
        persistTeamNameDraft()
    }

    @discardableResult
    func startGame() -> Bool {
        guard canStartGame else {
            return false
        }

        updateTeamNames(teamA: trimmedTeamAName, teamB: trimmedTeamBName)
        persistTeamNameDraft()
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

    static let defaultPlaceholderTeamNames = ("Team A", "Team B")
}

private extension NewGameViewModel {
    func restorePersistedTeamNamesIfNeeded(initialPairIndex: Int?) {
        guard let draft = settingsStore.newGameTeamNameDraft else {
            return
        }

        let selectedPair = seededPair(for: initialPairIndex)
        let fallbackTeamA = selectedPair?.teamA ?? settings.teamAName
        let fallbackTeamB = selectedPair?.teamB ?? settings.teamBName

        let resolvedTeamA = resolveStoredTeamName(
            storedName: draft.teamAName,
            source: draft.teamASource,
            fallback: fallbackTeamA
        )
        let resolvedTeamB = resolveStoredTeamName(
            storedName: draft.teamBName,
            source: draft.teamBSource,
            fallback: fallbackTeamB
        )

        teamANameSource = resolvedTeamA.source
        teamBNameSource = resolvedTeamB.source
        updateTeamNames(teamA: resolvedTeamA.name, teamB: resolvedTeamB.name)
    }

    func seedSuggestedTeamNamesIfNeeded(initialPairIndex: Int?) {
        let pairs = Self.suggestedTeamNamePairs
        guard shouldSeedSuggestedTeamNames,
              !pairs.isEmpty else {
            return
        }

        guard let selectedPair = seededPair(for: initialPairIndex) else {
            return
        }

        teamANameSource = .random
        teamBNameSource = .random
        updateTeamNames(teamA: selectedPair.teamA, teamB: selectedPair.teamB)
    }

    var shouldSeedSuggestedTeamNames: Bool {
        let trimmedTeamA = trimmedTeamAName
        let trimmedTeamB = trimmedTeamBName

        let isDefaultPlaceholderPair =
            trimmedTeamA.caseInsensitiveCompare(Self.defaultPlaceholderTeamNames.0) == .orderedSame
            && trimmedTeamB.caseInsensitiveCompare(Self.defaultPlaceholderTeamNames.1) == .orderedSame

        let areBothEmpty = trimmedTeamA.isEmpty && trimmedTeamB.isEmpty

        return isDefaultPlaceholderPair || areBothEmpty
    }

    func updateTeamNames(teamA: String, teamB: String) {
        settings = GameSettings(
            teamAName: teamA,
            teamBName: teamB,
            numberOfRounds: settings.numberOfRounds,
            roundDurationSeconds: settings.roundDurationSeconds
        )
    }

    func persistTeamNameDraft() {
        settingsStore.setNewGameTeamNameDraft(
            NewGameTeamNameDraft(
                teamAName: trimmedTeamAName,
                teamBName: trimmedTeamBName,
                teamASource: teamANameSource,
                teamBSource: teamBNameSource
            )
        )
    }

    func seededPair(for initialPairIndex: Int?) -> TeamNamePair? {
        let pairs = Self.suggestedTeamNamePairs
        guard !pairs.isEmpty else {
            return nil
        }

        let selectedIndex = initialPairIndex.map { (($0 % pairs.count) + pairs.count) % pairs.count }
            ?? Int.random(in: 0..<pairs.count)
        suggestedTeamNamePairIndex = (selectedIndex + 1) % pairs.count
        return pairs[selectedIndex]
    }

    func resolveStoredTeamName(
        storedName: String,
        source: NewGameTeamNameSource,
        fallback: String
    ) -> (name: String, source: NewGameTeamNameSource) {
        let trimmedName = storedName.trimmingCharacters(in: .whitespacesAndNewlines)

        switch source {
        case .manual:
            guard !trimmedName.isEmpty else {
                return (fallback, .random)
            }
            return (trimmedName, .manual)
        case .random:
            return (fallback, .random)
        }
    }
}
