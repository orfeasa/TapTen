import Foundation
import Testing
@testable import TapTen

struct QuestionPackTestingConfigurationTests {
    @Test
    func sandboxReceiptEnablesTesterUnlocksWithoutInfoPlistFlag() {
        let receiptURL = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application/test/StoreKit/sandboxReceipt")

        let isEnabled = QuestionPackTestingConfiguration.inferredTesterUnlocksEnabled(
            infoDictionaryValue: nil,
            receiptURL: receiptURL
        )

        #expect(isEnabled)
    }

    @Test
    func explicitInfoPlistFlagFalseOverridesSandboxFallback() {
        let receiptURL = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application/test/StoreKit/sandboxReceipt")

        let isEnabled = QuestionPackTestingConfiguration.inferredTesterUnlocksEnabled(
            infoDictionaryValue: false,
            receiptURL: receiptURL
        )

        #expect(!isEnabled)
    }

    @Test
    func nonSandboxReceiptKeepsTesterUnlocksDisabledWithoutOverrides() {
        let receiptURL = URL(fileURLWithPath: "/private/var/mobile/Containers/Data/Application/test/StoreKit/receipt")

        let isEnabled = QuestionPackTestingConfiguration.inferredTesterUnlocksEnabled(
            infoDictionaryValue: nil,
            receiptURL: receiptURL
        )

        #expect(!isEnabled)
    }
}
