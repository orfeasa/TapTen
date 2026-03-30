import Foundation
import Testing
@testable import TapTen

struct CategoryCatalogServiceTests {
    @Test
    func lockedPremiumCategoriesStayOutOfTheSetupCatalog() throws {
        let defaults = try makeDefaults()
        let files = try writePackFiles([
            try makePackFileData(
                id: "starter-pack",
                title: "Everyday Life",
                category: "Everyday Life"
            ),
            try makePackFileData(
                id: "after-dark-vol-1",
                title: "After Dark Vol. 1",
                category: "After Dark",
                monetization: [
                    "access": "premium",
                    "storeProductID": "com.tapten.pack.after-dark-vol-1"
                ]
            )
        ])
        defer { try? FileManager.default.removeItem(at: files.directoryURL) }

        let service = CategoryCatalogService(
            questionPackLibrary: QuestionPackLibrary(
                bundledLoader: QuestionPackLoader(packFileURLs: files.fileURLs)
            ),
            entitlementStore: QuestionPackEntitlementStore(defaults: defaults)
        )

        #expect(service.categories().map(\.name) == ["Everyday Life"])
    }

    @Test
    func unlockedPremiumCategoriesAppearAfterTheStarterLibrary() throws {
        let defaults = try makeDefaults()
        let store = QuestionPackEntitlementStore(defaults: defaults)
        store.markUnlocked(productID: "com.tapten.pack.after-dark-vol-1")

        let files = try writePackFiles([
            try makePackFileData(
                id: "starter-pack",
                title: "Everyday Life",
                category: "Everyday Life"
            ),
            try makePackFileData(
                id: "after-dark-vol-1",
                title: "After Dark Vol. 1",
                category: "After Dark",
                monetization: [
                    "access": "premium",
                    "storeProductID": "com.tapten.pack.after-dark-vol-1"
                ]
            ),
            try makePackFileData(
                id: "date-night",
                title: "Date Night",
                category: "Date Night",
                monetization: [
                    "access": "premium",
                    "storeProductID": "com.tapten.pack.date-night"
                ]
            )
        ])
        defer { try? FileManager.default.removeItem(at: files.directoryURL) }

        let service = CategoryCatalogService(
            questionPackLibrary: QuestionPackLibrary(
                bundledLoader: QuestionPackLoader(packFileURLs: files.fileURLs)
            ),
            entitlementStore: store
        )

        #expect(service.categories().map(\.name) == [
            "Everyday Life",
            "After Dark",
            "Date Night"
        ])
    }

    @Test
    func packLoadFailuresFallBackToTheStarterLibraryCatalog() {
        let service = CategoryCatalogService(
            questionPackLibrary: QuestionPackLibrary(
                bundledLoader: QuestionPackLoader(packFileURLs: [])
            )
        )

        #expect(service.categories().map(\.name) == CategoryCatalogService.starterCategoryNames)
    }

    @Test
    func localCustomCategoriesAppearAfterTheStarterLibrary() throws {
        let defaults = try makeDefaults()
        let files = try writePackFiles([
            try makePackFileData(
                id: "starter-pack",
                title: "Everyday Life",
                category: "Everyday Life"
            )
        ])
        defer { try? FileManager.default.removeItem(at: files.directoryURL) }

        let localDirectoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: localDirectoryURL) }

        let localStore = LocalQuestionPackStore(baseDirectoryURL: localDirectoryURL)
        try localStore.savePack(
            makeCustomPack(
                id: "inside-jokes-pack",
                title: "Inside Jokes",
                category: "Inside Jokes"
            )
        )

        let service = CategoryCatalogService(
            questionPackLibrary: QuestionPackLibrary(
                bundledLoader: QuestionPackLoader(packFileURLs: files.fileURLs),
                localPackStore: localStore
            ),
            entitlementStore: QuestionPackEntitlementStore(defaults: defaults)
        )

        #expect(service.categories().map(\.name) == ["Everyday Life", "Inside Jokes"])
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "CategoryCatalogServiceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private func writePackFiles(
    _ packDataByFileName: [(fileName: String, data: Data)]
) throws -> (directoryURL: URL, fileURLs: [URL]) {
    let directoryURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(
        at: directoryURL,
        withIntermediateDirectories: true,
        attributes: nil
    )

    let fileURLs = try packDataByFileName.map { entry in
        let fileURL = directoryURL.appendingPathComponent(entry.fileName)
        try entry.data.write(to: fileURL)
        return fileURL
    }

    return (directoryURL, fileURLs)
}

private func makePackFileData(
    id: String,
    title: String,
    category: String,
    monetization: [String: Any]? = nil
) throws -> (fileName: String, data: Data) {
    var payload: [String: Any] = [
        "id": id,
        "title": title,
        "languageCode": "en",
        "questions": [
            [
                "id": "\(id)-q1",
                "category": category,
                "prompt": "Prompt for \(title)",
                "difficultyTier": "medium",
                "difficultyScore": 19,
                "validationStyle": "editorial",
                "sourceURL": "https://example.com/\(id)",
                "answers": [
                    ["text": "Answer 1", "points": 1],
                    ["text": "Answer 2", "points": 1],
                    ["text": "Answer 3", "points": 1],
                    ["text": "Answer 4", "points": 2],
                    ["text": "Answer 5", "points": 2],
                    ["text": "Answer 6", "points": 2],
                    ["text": "Answer 7", "points": 2],
                    ["text": "Answer 8", "points": 2],
                    ["text": "Answer 9", "points": 3],
                    ["text": "Answer 10", "points": 3]
                ]
            ]
        ]
    ]

    if let monetization {
        payload["monetization"] = monetization
    }

    return (
        fileName: "\(id).json",
        data: try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    )
}

private func makeCustomPack(id: String, title: String, category: String) -> QuestionPack {
    QuestionPack(
        id: id,
        title: title,
        languageCode: "en",
        questions: [
            Question(
                id: "\(id)-q1",
                category: category,
                prompt: "Prompt for \(title)",
                difficultyTier: .medium,
                difficultyScore: 19,
                validationStyle: .editorial,
                sourceURL: LocalQuestionPackStore.placeholderSourceURL(forQuestionID: "\(id)-q1"),
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
        origin: .customLocal
    )
}
