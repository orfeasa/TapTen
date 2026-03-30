import Foundation
import Testing
@testable import TapTen

struct LocalQuestionPackStoreTests {
    @Test
    func saveAndLoadRoundTripsCustomPackData() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let store = LocalQuestionPackStore(baseDirectoryURL: directoryURL)
        let originalPack = makePack(
            id: "local-pack-1",
            title: "Office Banter",
            category: "Work & School",
            monetization: QuestionPackMonetization(
                access: .premium,
                storeProductID: "com.tapten.should.not.persist"
            ),
            origin: .bundled
        )

        try store.savePack(originalPack)
        let loadedPacks = try store.loadPacks()

        #expect(loadedPacks.count == 1)
        #expect(loadedPacks[0].id == "local-pack-1")
        #expect(loadedPacks[0].title == "Office Banter")
        #expect(loadedPacks[0].origin == .customLocal)
        #expect(loadedPacks[0].monetization == nil)
        #expect(loadedPacks[0].questions.first?.category == "Work & School")
    }

    @Test
    func deleteRemovesSavedPackFromStore() throws {
        let directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directoryURL) }

        let store = LocalQuestionPackStore(baseDirectoryURL: directoryURL)
        try store.savePack(
            makePack(
                id: "local-pack-1",
                title: "Office Banter",
                category: "Work & School"
            )
        )
        try store.savePack(
            makePack(
                id: "local-pack-2",
                title: "Holiday Chaos",
                category: "Travel"
            )
        )

        try store.deletePack(id: "local-pack-1")

        let loadedPacks = try store.loadPacks()
        #expect(loadedPacks.map(\.id) == ["local-pack-2"])
    }
}

private func makePack(
    id: String,
    title: String,
    category: String,
    monetization: QuestionPackMonetization? = nil,
    origin: QuestionPackOrigin = .customLocal
) -> QuestionPack {
    let questionID = "\(id)-q1"

    return QuestionPack(
        id: id,
        title: title,
        languageCode: "en",
        questions: [
            Question(
                id: questionID,
                category: category,
                prompt: "Prompt for \(title)",
                difficultyTier: .medium,
                difficultyScore: 19,
                validationStyle: .editorial,
                sourceURL: LocalQuestionPackStore.placeholderSourceURL(forQuestionID: questionID),
                answers: [
                    AnswerOption(text: "Answer 1", points: 1),
                    AnswerOption(text: "Answer 2", points: 1),
                    AnswerOption(text: "Answer 3", points: 1),
                    AnswerOption(text: "Answer 4", points: 2),
                    AnswerOption(text: "Answer 5", points: 2),
                    AnswerOption(text: "Answer 6", points: 2),
                    AnswerOption(text: "Answer 7", points: 2),
                    AnswerOption(text: "Answer 8", points: 2),
                    AnswerOption(text: "Answer 9", points: 3),
                    AnswerOption(text: "Answer 10", points: 3)
                ],
                quality: "custom"
            )
        ],
        monetization: monetization,
        origin: origin
    )
}
