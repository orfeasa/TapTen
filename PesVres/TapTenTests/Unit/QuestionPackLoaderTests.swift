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
        #expect(packs[0].questions[0].answers.count == 10)
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
}

private func makeValidPackData(answerCount: Int = 10, pointsForFirstAnswer: Int = 1) throws -> Data {
    var answers: [[String: Any]] = []
    for index in 0..<answerCount {
        let points = index == 0 ? pointsForFirstAnswer : 1
        answers.append([
            "text": "Answer \(index + 1)",
            "points": points
        ])
    }

    let json: [String: Any] = [
        "id": "starter-pack-v1",
        "title": "Starter Pack",
        "languageCode": "en",
        "questions": [
            [
                "id": "question-1",
                "category": "Factual",
                "prompt": "Sample prompt",
                "validationStyle": "factual",
                "sourceURL": "https://example.com/source",
                "answers": answers
            ]
        ]
    ]

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
