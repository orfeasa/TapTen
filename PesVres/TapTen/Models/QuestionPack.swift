import Foundation

enum QuestionPackOrigin: String, Equatable, Codable, Sendable {
    case bundled
    case customLocal
}

enum QuestionPackAccess: String, Equatable, Codable, Sendable {
    case free
    case premium
}

struct QuestionPackMonetization: Equatable, Codable, Sendable {
    let access: QuestionPackAccess
    let storeProductID: String?
    let bundleProductIDs: [String]
    let merchandisingLabel: String?

    init(
        access: QuestionPackAccess,
        storeProductID: String? = nil,
        bundleProductIDs: [String] = [],
        merchandisingLabel: String? = nil
    ) {
        self.access = access
        self.storeProductID = storeProductID
        self.bundleProductIDs = bundleProductIDs
        self.merchandisingLabel = merchandisingLabel
    }
}

struct QuestionPack: Equatable, Codable, Sendable {
    let id: String
    let title: String
    let summary: String?
    let languageCode: String
    let questions: [Question]
    let packVersion: String?
    let monetization: QuestionPackMonetization?
    let origin: QuestionPackOrigin

    init(
        id: String,
        title: String,
        summary: String? = nil,
        languageCode: String,
        questions: [Question],
        packVersion: String? = nil,
        monetization: QuestionPackMonetization? = nil,
        origin: QuestionPackOrigin = .bundled
    ) {
        self.id = id
        self.title = title
        self.summary = summary
        self.languageCode = languageCode
        self.questions = questions
        self.packVersion = packVersion
        self.monetization = monetization
        self.origin = origin
    }
}

extension QuestionPack {
    var access: QuestionPackAccess {
        monetization?.access ?? .free
    }

    var isPremium: Bool {
        access == .premium
    }

    var storeProductID: String? {
        monetization?.storeProductID
    }

    var bundleProductIDs: [String] {
        monetization?.bundleProductIDs ?? []
    }

    var merchandisingLabel: String? {
        monetization?.merchandisingLabel
    }
}
