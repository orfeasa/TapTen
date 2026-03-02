import Foundation
import Observation

@Observable
final class AppSettingsStore {
    static let shared = AppSettingsStore()

    private enum Keys {
        static let soundsEnabled = "settings.soundsEnabled"
        static let hapticsEnabled = "settings.hapticsEnabled"
        static let defaultRounds = "settings.defaultRounds"
        static let defaultTimerSeconds = "settings.defaultTimerSeconds"
    }

    private let defaults: UserDefaults

    var soundsEnabled: Bool {
        didSet { defaults.set(soundsEnabled, forKey: Keys.soundsEnabled) }
    }

    var hapticsEnabled: Bool {
        didSet { defaults.set(hapticsEnabled, forKey: Keys.hapticsEnabled) }
    }

    var defaultRounds: Int {
        didSet {
            defaultRounds = min(max(defaultRounds, 1), 10)
            defaults.set(defaultRounds, forKey: Keys.defaultRounds)
        }
    }

    var defaultTimerSeconds: Int {
        didSet {
            let clamped = min(max(defaultTimerSeconds, 30), 180)
            // Keep timer aligned to game step size.
            defaultTimerSeconds = (clamped / 5) * 5
            defaults.set(defaultTimerSeconds, forKey: Keys.defaultTimerSeconds)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        if defaults.object(forKey: Keys.soundsEnabled) == nil {
            defaults.set(true, forKey: Keys.soundsEnabled)
        }
        if defaults.object(forKey: Keys.hapticsEnabled) == nil {
            defaults.set(true, forKey: Keys.hapticsEnabled)
        }
        if defaults.object(forKey: Keys.defaultRounds) == nil {
            defaults.set(5, forKey: Keys.defaultRounds)
        }
        if defaults.object(forKey: Keys.defaultTimerSeconds) == nil {
            defaults.set(60, forKey: Keys.defaultTimerSeconds)
        }

        soundsEnabled = defaults.bool(forKey: Keys.soundsEnabled)
        hapticsEnabled = defaults.bool(forKey: Keys.hapticsEnabled)
        defaultRounds = defaults.integer(forKey: Keys.defaultRounds)
        defaultTimerSeconds = defaults.integer(forKey: Keys.defaultTimerSeconds)
    }

    var defaultGameSettings: GameSettings {
        GameSettings(
            teamAName: "Team A",
            teamBName: "Team B",
            numberOfRounds: defaultRounds,
            roundDurationSeconds: defaultTimerSeconds
        )
    }
}
