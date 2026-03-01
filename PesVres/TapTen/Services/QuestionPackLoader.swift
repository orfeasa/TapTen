import Foundation

enum QuestionPackLoaderError: LocalizedError {
    case noPackFilesFound
    case packFileNotFound(name: String)
    case unreadablePackFile(name: String)
    case malformedJSON(name: String, reason: String)
    case invalidPack(name: String, reason: String)

    var errorDescription: String? {
        switch self {
        case .noPackFilesFound:
            return "No local question-pack JSON files were found in the app bundle."
        case .packFileNotFound(let name):
            return "Question pack '\(name)' was not found in the app bundle."
        case .unreadablePackFile(let name):
            return "Question pack '\(name)' could not be read from disk."
        case .malformedJSON(let name, let reason):
            return "Question pack '\(name)' has malformed JSON: \(reason)"
        case .invalidPack(let name, let reason):
            return "Question pack '\(name)' is invalid: \(reason)"
        }
    }
}

struct QuestionPackLoader {
    private let bundle: Bundle
    private let decoder: JSONDecoder
    private let explicitPackFileURLs: [URL]?

    init(
        bundle: Bundle = .main,
        decoder: JSONDecoder = JSONDecoder(),
        packFileURLs: [URL]? = nil
    ) {
        self.bundle = bundle
        self.decoder = decoder
        self.explicitPackFileURLs = packFileURLs
    }

    func loadAllPacks() throws -> [QuestionPack] {
        let fileURLs = try resolvedPackFileURLs()
            .sorted { $0.lastPathComponent < $1.lastPathComponent }

        return try fileURLs.map { try loadPack(fromFileURL: $0) }
    }

    func loadPack(named resourceName: String) throws -> QuestionPack {
        if let explicitPackFileURLs {
            guard let fileURL = explicitPackFileURLs.first(where: { $0.deletingPathExtension().lastPathComponent == resourceName }) else {
                throw QuestionPackLoaderError.packFileNotFound(name: resourceName)
            }
            return try loadPack(fromFileURL: fileURL)
        }

        guard let fileURL = bundledPackFileURL(named: resourceName) else {
            throw QuestionPackLoaderError.packFileNotFound(name: resourceName)
        }

        return try loadPack(fromFileURL: fileURL)
    }

    func loadPack(from data: Data, fileName: String) throws -> QuestionPack {
        let dto: QuestionPackDTO
        do {
            dto = try decoder.decode(QuestionPackDTO.self, from: data)
        } catch {
            throw QuestionPackLoaderError.malformedJSON(name: fileName, reason: error.localizedDescription)
        }

        return try dto.validated(fileName: fileName)
    }

    private func loadPack(fromFileURL fileURL: URL) throws -> QuestionPack {
        let fileName = fileURL.lastPathComponent

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw QuestionPackLoaderError.unreadablePackFile(name: fileName)
        }

        return try loadPack(from: data, fileName: fileName)
    }

    private func resolvedPackFileURLs() throws -> [URL] {
        if let explicitPackFileURLs {
            if explicitPackFileURLs.isEmpty {
                throw QuestionPackLoaderError.noPackFilesFound
            }
            return explicitPackFileURLs
        }

        for subdirectory in ["QuestionPacks", "Resources/QuestionPacks"] {
            if let urls = bundle.urls(forResourcesWithExtension: "json", subdirectory: subdirectory), !urls.isEmpty {
                return urls
            }
        }

        if let rootJSONURLs = bundle.urls(forResourcesWithExtension: "json", subdirectory: nil) {
            let filtered = rootJSONURLs.filter { !$0.lastPathComponent.hasSuffix("Contents.json") }
            if !filtered.isEmpty {
                return filtered
            }
        }

        throw QuestionPackLoaderError.noPackFilesFound
    }

    private func bundledPackFileURL(named resourceName: String) -> URL? {
        for subdirectory in ["QuestionPacks", "Resources/QuestionPacks"] {
            if let url = bundle.url(forResource: resourceName, withExtension: "json", subdirectory: subdirectory) {
                return url
            }
        }

        if let rootURL = bundle.url(forResource: resourceName, withExtension: "json", subdirectory: nil) {
            return rootURL
        }

        return nil
    }
}

private struct QuestionPackDTO: Decodable {
    let id: String
    let title: String
    let languageCode: String
    let questions: [QuestionDTO]

    func validated(fileName: String) throws -> QuestionPack {
        guard !id.trimmed.isEmpty else {
            throw QuestionPackLoaderError.invalidPack(name: fileName, reason: "Missing pack id.")
        }

        guard !title.trimmed.isEmpty else {
            throw QuestionPackLoaderError.invalidPack(name: fileName, reason: "Missing pack title.")
        }

        guard !languageCode.trimmed.isEmpty else {
            throw QuestionPackLoaderError.invalidPack(name: fileName, reason: "Missing language code.")
        }

        guard !questions.isEmpty else {
            throw QuestionPackLoaderError.invalidPack(name: fileName, reason: "Pack must include at least one question.")
        }

        let validatedQuestions = try questions.enumerated().map { index, question in
            try question.validated(questionIndex: index, fileName: fileName)
        }

        return QuestionPack(
            id: id.trimmed,
            title: title.trimmed,
            languageCode: languageCode.trimmed,
            questions: validatedQuestions
        )
    }
}

private struct QuestionDTO: Decodable {
    let id: String
    let category: String
    let prompt: String
    let difficulty: QuestionDifficulty
    let validationStyle: ValidationStyle
    let sourceURL: String
    let answers: [AnswerOptionDTO]

    func validated(questionIndex: Int, fileName: String) throws -> Question {
        let questionLabel = "Question \(questionIndex + 1)"

        guard !id.trimmed.isEmpty else {
            throw QuestionPackLoaderError.invalidPack(name: fileName, reason: "\(questionLabel): missing id.")
        }

        guard !category.trimmed.isEmpty else {
            throw QuestionPackLoaderError.invalidPack(name: fileName, reason: "\(questionLabel): missing category.")
        }

        guard !prompt.trimmed.isEmpty else {
            throw QuestionPackLoaderError.invalidPack(name: fileName, reason: "\(questionLabel): missing prompt.")
        }

        guard answers.count == 10 else {
            throw QuestionPackLoaderError.invalidPack(
                name: fileName,
                reason: "\(questionLabel): expected exactly 10 answers, found \(answers.count)."
            )
        }

        guard let parsedURL = URL(string: sourceURL), ["http", "https"].contains(parsedURL.scheme?.lowercased() ?? "") else {
            throw QuestionPackLoaderError.invalidPack(name: fileName, reason: "\(questionLabel): sourceURL must be an http/https URL.")
        }

        let validatedAnswers = try answers.enumerated().map { index, answer in
            try answer.validated(questionLabel: questionLabel, answerIndex: index, fileName: fileName)
        }

        let uniqueAnswerCount = Set(validatedAnswers.map { $0.text.lowercased() }).count
        guard uniqueAnswerCount == validatedAnswers.count else {
            throw QuestionPackLoaderError.invalidPack(name: fileName, reason: "\(questionLabel): answers must be unique.")
        }

        return Question(
            id: id.trimmed,
            category: category.trimmed,
            prompt: prompt.trimmed,
            difficulty: difficulty,
            validationStyle: validationStyle,
            sourceURL: parsedURL,
            answers: validatedAnswers
        )
    }
}

private struct AnswerOptionDTO: Decodable {
    let text: String
    let points: Int

    func validated(questionLabel: String, answerIndex: Int, fileName: String) throws -> AnswerOption {
        let answerLabel = "\(questionLabel), answer \(answerIndex + 1)"

        guard !text.trimmed.isEmpty else {
            throw QuestionPackLoaderError.invalidPack(name: fileName, reason: "\(answerLabel): text must not be empty.")
        }

        guard (1...5).contains(points) else {
            throw QuestionPackLoaderError.invalidPack(
                name: fileName,
                reason: "\(answerLabel): points must be between 1 and 5."
            )
        }

        return AnswerOption(text: text.trimmed, points: points)
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
