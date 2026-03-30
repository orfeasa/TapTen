import Foundation

struct QuestionPackLibrary {
    private let bundledLoader: QuestionPackLoader
    private let localPackStore: LocalQuestionPackStore

    init(
        bundledLoader: QuestionPackLoader = QuestionPackLoader(),
        localPackStore: LocalQuestionPackStore = LocalQuestionPackStore()
    ) {
        self.bundledLoader = bundledLoader
        self.localPackStore = localPackStore
    }

    func loadAllPacks() throws -> [QuestionPack] {
        try bundledLoader.loadAllPacks() + localPackStore.loadPacks()
    }

    func loadCustomPacks() throws -> [QuestionPack] {
        try localPackStore.loadPacks()
    }
}
