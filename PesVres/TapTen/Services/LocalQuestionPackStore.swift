import Foundation

enum LocalQuestionPackStoreError: LocalizedError {
    case applicationSupportUnavailable
    case unreadableStore(String)
    case invalidStore(String)
    case unwritableStore(String)

    var errorDescription: String? {
        switch self {
        case .applicationSupportUnavailable:
            return "The app could not access local storage for custom packs."
        case .unreadableStore(let reason):
            return "Custom packs could not be read from local storage: \(reason)"
        case .invalidStore(let reason):
            return "Custom packs in local storage are invalid: \(reason)"
        case .unwritableStore(let reason):
            return "Custom packs could not be saved locally: \(reason)"
        }
    }
}

struct LocalQuestionPackStore {
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let baseDirectoryURL: URL?

    init(
        fileManager: FileManager = .default,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder(),
        baseDirectoryURL: URL? = nil
    ) {
        self.fileManager = fileManager
        self.encoder = encoder
        self.decoder = decoder
        self.baseDirectoryURL = baseDirectoryURL
    }

    func loadPacks() throws -> [QuestionPack] {
        let storeURL = try storeFileURL()
        guard fileManager.fileExists(atPath: storeURL.path) else {
            return []
        }

        let data: Data
        do {
            data = try Data(contentsOf: storeURL)
        } catch {
            throw LocalQuestionPackStoreError.unreadableStore(error.localizedDescription)
        }

        let packs: [QuestionPack]
        do {
            packs = try decoder.decode([QuestionPack].self, from: data)
        } catch {
            throw LocalQuestionPackStoreError.invalidStore(error.localizedDescription)
        }

        return packs
            .filter { $0.origin == .customLocal }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    func savePack(_ pack: QuestionPack) throws {
        var packs = try loadPacks()
        let normalizedPack = QuestionPack(
            id: pack.id,
            title: pack.title,
            summary: pack.summary,
            languageCode: pack.languageCode,
            questions: pack.questions,
            packVersion: pack.packVersion,
            monetization: nil,
            origin: .customLocal
        )

        if let existingIndex = packs.firstIndex(where: { $0.id == normalizedPack.id }) {
            packs[existingIndex] = normalizedPack
        } else {
            packs.append(normalizedPack)
        }

        try write(packs)
    }

    func deletePack(id: String) throws {
        let updatedPacks = try loadPacks().filter { $0.id != id }
        try write(updatedPacks)
    }

    func storeFileURL() throws -> URL {
        let rootDirectory: URL
        if let baseDirectoryURL {
            rootDirectory = baseDirectoryURL
        } else if let applicationSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            rootDirectory = applicationSupportURL.appendingPathComponent("TapTen", isDirectory: true)
        } else {
            throw LocalQuestionPackStoreError.applicationSupportUnavailable
        }

        let customPacksDirectory = rootDirectory.appendingPathComponent("CustomPacks", isDirectory: true)

        do {
            try fileManager.createDirectory(at: customPacksDirectory, withIntermediateDirectories: true)
        } catch {
            throw LocalQuestionPackStoreError.unwritableStore(error.localizedDescription)
        }

        return customPacksDirectory.appendingPathComponent("custom-packs.json")
    }

    static func placeholderSourceURL(forQuestionID questionID: String) -> URL {
        URL(string: "https://tapten.local/custom/\(questionID)")!
    }

    private func write(_ packs: [QuestionPack]) throws {
        let storeURL = try storeFileURL()

        let data: Data
        do {
            data = try encoder.encode(packs.sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
            })
        } catch {
            throw LocalQuestionPackStoreError.unwritableStore(error.localizedDescription)
        }

        do {
            try data.write(to: storeURL, options: .atomic)
        } catch {
            throw LocalQuestionPackStoreError.unwritableStore(error.localizedDescription)
        }
    }
}
