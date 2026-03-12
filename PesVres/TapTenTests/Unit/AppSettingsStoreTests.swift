import Foundation
import Testing
@testable import TapTen

struct AppSettingsStoreTests {
    @Test
    func defaultRoundsAreClampedAndPersisted() throws {
        let suiteName = "AppSettingsStoreTests.rounds.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AppSettingsStore(defaults: defaults)
        store.setDefaultRounds(99)

        #expect(store.defaultRounds == 10)
        #expect(store.defaultGameSettings.numberOfRounds == 10)

        let reloadedStore = AppSettingsStore(defaults: defaults)
        #expect(reloadedStore.defaultRounds == 10)
    }

    @Test
    func defaultTimerSecondsAreRoundedAndPersisted() throws {
        let suiteName = "AppSettingsStoreTests.timer.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = AppSettingsStore(defaults: defaults)
        store.setDefaultTimerSeconds(73)

        #expect(store.defaultTimerSeconds == 70)
        #expect(store.defaultGameSettings.roundDurationSeconds == 70)

        let reloadedStore = AppSettingsStore(defaults: defaults)
        #expect(reloadedStore.defaultTimerSeconds == 70)
    }
}
