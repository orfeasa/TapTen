import Foundation
import Testing
@testable import TapTen

struct QuestionPackLoaderTests {
    @Test
    func loadsPackFromLocalJSONFile() throws {
        let fileURL = try writeTemporaryPackFile(named: "SamplePack.json", data: makeValidPackData())
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        let loader = QuestionPackLoader(packFileURLs: [fileURL])
        let packs = try loader.loadAllPacks()

        #expect(packs.count == 1)
        #expect(packs[0].id == "starter-pack-v1")
        #expect(packs[0].questions.count == 1)
        #expect(packs[0].questions[0].difficultyTier == .medium)
        #expect(packs[0].questions[0].difficulty == .medium)
        #expect(packs[0].questions[0].difficultyScore == 19)
        #expect(packs[0].questions[0].answers.count == 10)
        #expect(packs[0].summary == nil)
        #expect(packs[0].packVersion == nil)
        #expect(packs[0].access == .free)
        #expect(packs[0].isPremium == false)
        #expect(packs[0].storeProductID == nil)
        #expect(packs[0].bundleProductIDs.isEmpty)
        #expect(packs[0].merchandisingLabel == nil)
        #expect(packs[0].questions[0].contentType == nil)
        #expect(packs[0].questions[0].tags == nil)
    }

    @Test
    func richMetadataDecodesAndNormalizesOptionalValues() throws {
        let loader = QuestionPackLoader()
        let data = try makeValidPackData(
            summary: "  Party-night premium prompts. ",
            packVersion: "2.0",
            monetization: [
                "access": "premium",
                "storeProductID": " com.tapten.pack.after-dark-1 ",
                "bundleProductIDs": [" launch-trio ", "", "Launch-Trio"],
                "merchandisingLabel": " New "
            ],
            contentType: "factual-list",
            difficultyTier: "medium",
            difficultyScore: 19,
            quality: "reviewed",
            tags: [" ranked ", "", "Trivia", "RANKED"],
            difficultyNotes: "Tight list with a few tricky entries.",
            editorialNotes: "  "
        )

        let pack = try loader.loadPack(from: data, fileName: "WithMetadata.json")
        let question = try #require(pack.questions.first)

        #expect(pack.packVersion == "2.0")
        #expect(pack.summary == "Party-night premium prompts.")
        #expect(pack.access == .premium)
        #expect(pack.isPremium)
        #expect(pack.storeProductID == "com.tapten.pack.after-dark-1")
        #expect(pack.bundleProductIDs == ["launch-trio"])
        #expect(pack.merchandisingLabel == "New")
        #expect(question.contentType == "factual-list")
        #expect(question.difficultyTier == .medium)
        #expect(question.difficultyScore == 19)
        #expect(question.quality == "reviewed")
        #expect(question.tags == ["ranked", "Trivia"])
        #expect(question.difficultyNotes == "Tight list with a few tricky entries.")
        #expect(question.editorialNotes == nil)
    }

    @Test
    func malformedJSONThrowsCleanError() throws {
        let loader = QuestionPackLoader()
        let brokenData = Data("{ not-json }".utf8)

        do {
            _ = try loader.loadPack(from: brokenData, fileName: "BrokenPack.json")
            Issue.record("Expected malformed JSON error.")
        } catch let error as QuestionPackLoaderError {
            switch error {
            case .malformedJSON(let fileName, _):
                #expect(fileName == "BrokenPack.json")
            default:
                Issue.record("Expected .malformedJSON, got \(error.localizedDescription)")
            }
        }
    }

    @Test
    func invalidAnswerCountThrowsCleanError() throws {
        let loader = QuestionPackLoader()
        let invalidData = try makeValidPackData(answerCount: 9)

        do {
            _ = try loader.loadPack(from: invalidData, fileName: "InvalidAnswerCount.json")
            Issue.record("Expected invalid pack error.")
        } catch let error as QuestionPackLoaderError {
            switch error {
            case .invalidPack(let fileName, let reason):
                #expect(fileName == "InvalidAnswerCount.json")
                #expect(reason.contains("expected exactly 10 answers"))
            default:
                Issue.record("Expected .invalidPack, got \(error.localizedDescription)")
            }
        }
    }

    @Test
    func outOfRangePointsThrowsCleanError() throws {
        let loader = QuestionPackLoader()
        let invalidData = try makeValidPackData(pointsForFirstAnswer: 6)

        do {
            _ = try loader.loadPack(from: invalidData, fileName: "InvalidPoints.json")
            Issue.record("Expected invalid pack error.")
        } catch let error as QuestionPackLoaderError {
            switch error {
            case .invalidPack(let fileName, let reason):
                #expect(fileName == "InvalidPoints.json")
                #expect(reason.contains("points must be between 1 and 5"))
            default:
                Issue.record("Expected .invalidPack, got \(error.localizedDescription)")
            }
        }
    }

    @Test
    func unknownDifficultyThrowsCleanError() throws {
        let loader = QuestionPackLoader()
        let invalidData = try makeValidPackData(difficulty: "legendary")

        do {
            _ = try loader.loadPack(from: invalidData, fileName: "InvalidDifficulty.json")
            Issue.record("Expected malformed JSON error.")
        } catch let error as QuestionPackLoaderError {
            switch error {
            case .malformedJSON(let fileName, _):
                #expect(fileName == "InvalidDifficulty.json")
            default:
                Issue.record("Expected .malformedJSON, got \(error.localizedDescription)")
            }
        }
    }

    @Test
    func mismatchedDifficultyScoreThrowsCleanError() throws {
        let loader = QuestionPackLoader()
        let invalidData = try makeValidPackData(
            difficultyTier: "medium",
            difficultyScore: 25
        )

        do {
            _ = try loader.loadPack(from: invalidData, fileName: "InvalidDifficultyScore.json")
            Issue.record("Expected invalid pack error.")
        } catch let error as QuestionPackLoaderError {
            switch error {
            case .invalidPack(let fileName, let reason):
                #expect(fileName == "InvalidDifficultyScore.json")
                #expect(reason.contains("difficultyScore 25 must equal the sum of answer points (19)"))
            default:
                Issue.record("Expected .invalidPack, got \(error.localizedDescription)")
            }
        }
    }

    @Test
    func difficultyTierBandMismatchThrowsCleanError() throws {
        let loader = QuestionPackLoader()
        let invalidData = try makeValidPackData(
            difficultyTier: "easy",
            difficultyScore: 19
        )

        do {
            _ = try loader.loadPack(from: invalidData, fileName: "InvalidDifficultyTier.json")
            Issue.record("Expected invalid pack error.")
        } catch let error as QuestionPackLoaderError {
            switch error {
            case .invalidPack(let fileName, let reason):
                #expect(fileName == "InvalidDifficultyTier.json")
                #expect(reason.contains("difficultyTier 'easy' does not match difficultyScore 19"))
            default:
                Issue.record("Expected .invalidPack, got \(error.localizedDescription)")
            }
        }
    }

    @Test
    func legacyDifficultyFieldRemainsCompatibleWhenTierAndScoreAreMissing() throws {
        let loader = QuestionPackLoader()
        let data = try makeValidPackData(difficulty: "easy")

        let pack = try loader.loadPack(from: data, fileName: "LegacyDifficulty.json")
        let question = try #require(pack.questions.first)

        // Legacy difficulty can differ from score bands in existing packs; score is canonical.
        #expect(question.difficultyTier == .medium)
        #expect(question.difficulty == .medium)
        #expect(question.difficultyScore == 19)
    }

    @Test
    func scoreOutsideDifficultyBandsThrowsCleanError() throws {
        let loader = QuestionPackLoader()
        let invalidData = try makeValidPackData(
            pointsForFirstAnswer: 5,
            pointsForRemainingAnswers: 5
        )

        do {
            _ = try loader.loadPack(from: invalidData, fileName: "OutOfBandScore.json")
            Issue.record("Expected invalid pack error.")
        } catch let error as QuestionPackLoaderError {
            switch error {
            case .invalidPack(let fileName, let reason):
                #expect(fileName == "OutOfBandScore.json")
                #expect(reason.contains("difficultyScore 50 is out of range"))
            default:
                Issue.record("Expected .invalidPack, got \(error.localizedDescription)")
            }
        }
    }

    @Test
    func premiumPackWithoutStoreProductIDThrowsCleanError() throws {
        let loader = QuestionPackLoader()
        let invalidData = try makeValidPackData(
            monetization: [
                "access": "premium"
            ]
        )

        do {
            _ = try loader.loadPack(from: invalidData, fileName: "PremiumMissingProductID.json")
            Issue.record("Expected invalid pack error.")
        } catch let error as QuestionPackLoaderError {
            switch error {
            case .invalidPack(let fileName, let reason):
                #expect(fileName == "PremiumMissingProductID.json")
                #expect(reason.contains("must include a storeProductID"))
            default:
                Issue.record("Expected .invalidPack, got \(error.localizedDescription)")
            }
        }
    }

    @Test
    func freePackCannotDefineStoreProductID() throws {
        let loader = QuestionPackLoader()
        let invalidData = try makeValidPackData(
            monetization: [
                "access": "free",
                "storeProductID": "com.tapten.pack.should-not-exist"
            ]
        )

        do {
            _ = try loader.loadPack(from: invalidData, fileName: "FreeWithProductID.json")
            Issue.record("Expected invalid pack error.")
        } catch let error as QuestionPackLoaderError {
            switch error {
            case .invalidPack(let fileName, let reason):
                #expect(fileName == "FreeWithProductID.json")
                #expect(reason.contains("marked free"))
                #expect(reason.contains("storeProductID"))
            default:
                Issue.record("Expected .invalidPack, got \(error.localizedDescription)")
            }
        }
    }
}

private func makeValidPackData(
    answerCount: Int = 10,
    pointsForFirstAnswer: Int = 1,
    pointsForRemainingAnswers: Int = 2,
    difficulty: String? = "medium",
    difficultyTier: String? = nil,
    difficultyScore: Int? = nil,
    summary: String? = nil,
    packVersion: String? = nil,
    monetization: [String: Any]? = nil,
    contentType: String? = nil,
    quality: String? = nil,
    tags: [String]? = nil,
    difficultyNotes: String? = nil,
    editorialNotes: String? = nil
) throws -> Data {
    var answers: [[String: Any]] = []
    for index in 0..<answerCount {
        let points = index == 0 ? pointsForFirstAnswer : pointsForRemainingAnswers
        answers.append([
            "text": "Answer \(index + 1)",
            "points": points
        ])
    }

    var question: [String: Any] = [
        "id": "question-1",
        "category": "Factual",
        "prompt": "Sample prompt",
        "validationStyle": "factual",
        "sourceURL": "https://example.com/source",
        "answers": answers
    ]
    if let difficulty {
        question["difficulty"] = difficulty
    }
    if let difficultyTier {
        question["difficultyTier"] = difficultyTier
    }
    if let difficultyScore {
        question["difficultyScore"] = difficultyScore
    }
    if let contentType {
        question["contentType"] = contentType
    }
    if let quality {
        question["quality"] = quality
    }
    if let tags {
        question["tags"] = tags
    }
    if let difficultyNotes {
        question["difficultyNotes"] = difficultyNotes
    }
    if let editorialNotes {
        question["editorialNotes"] = editorialNotes
    }

    var json: [String: Any] = [
        "id": "starter-pack-v1",
        "title": "Starter Pack",
        "languageCode": "en",
        "questions": [question]
    ]
    if let summary {
        json["summary"] = summary
    }
    if let packVersion {
        json["packVersion"] = packVersion
    }
    if let monetization {
        json["monetization"] = monetization
    }

    return try JSONSerialization.data(withJSONObject: json)
}

private func writeTemporaryPackFile(named fileName: String, data: Data) throws -> URL {
    let tempDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

    let fileURL = tempDirectory.appendingPathComponent(fileName)
    try data.write(to: fileURL, options: .atomic)
    return fileURL
}
