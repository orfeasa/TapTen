import Foundation
import Observation

enum NewGameTeamNameSource: String, Codable, Equatable, Sendable {
    case manual
    case random
}

struct NewGameTeamNameDraft: Codable, Equatable, Sendable {
    var teamAName: String
    var teamBName: String
    var teamASource: NewGameTeamNameSource
    var teamBSource: NewGameTeamNameSource
}

@Observable
final class AppSettingsStore {
    static let shared = AppSettingsStore()

    private enum Keys {
        static let soundsEnabled = "settings.soundsEnabled"
        static let hapticsEnabled = "settings.hapticsEnabled"
        static let defaultRounds = "settings.defaultRounds"
        static let defaultTimerSeconds = "settings.defaultTimerSeconds"
        static let newGameTeamNameDraft = "settings.newGameTeamNameDraft"
    }

    private let defaults: UserDefaults

    private(set) var soundsEnabled: Bool

    private(set) var hapticsEnabled: Bool

    private(set) var defaultRounds: Int

    private(set) var defaultTimerSeconds: Int

    private(set) var newGameTeamNameDraft: NewGameTeamNameDraft?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.soundsEnabled: true,
            Keys.hapticsEnabled: true,
            Keys.defaultRounds: 5,
            Keys.defaultTimerSeconds: 60
        ])

        soundsEnabled = defaults.bool(forKey: Keys.soundsEnabled)
        hapticsEnabled = defaults.bool(forKey: Keys.hapticsEnabled)
        defaultRounds = Self.clampedRounds(defaults.integer(forKey: Keys.defaultRounds))
        defaultTimerSeconds = Self.clampedTimerSeconds(defaults.integer(forKey: Keys.defaultTimerSeconds))
        newGameTeamNameDraft = Self.loadTeamNameDraft(from: defaults)

        defaults.set(defaultRounds, forKey: Keys.defaultRounds)
        defaults.set(defaultTimerSeconds, forKey: Keys.defaultTimerSeconds)
    }

    var defaultGameSettings: GameSettings {
        GameSettings(
            teamAName: "Team A",
            teamBName: "Team B",
            numberOfRounds: defaultRounds,
            roundDurationSeconds: defaultTimerSeconds
        )
    }

    func setSoundsEnabled(_ isEnabled: Bool) {
        soundsEnabled = isEnabled
        defaults.set(isEnabled, forKey: Keys.soundsEnabled)
    }

    func setHapticsEnabled(_ isEnabled: Bool) {
        hapticsEnabled = isEnabled
        defaults.set(isEnabled, forKey: Keys.hapticsEnabled)
    }

    func setDefaultRounds(_ rounds: Int) {
        let clampedRounds = Self.clampedRounds(rounds)
        defaultRounds = clampedRounds
        defaults.set(clampedRounds, forKey: Keys.defaultRounds)
    }

    func setDefaultTimerSeconds(_ seconds: Int) {
        let clampedSeconds = Self.clampedTimerSeconds(seconds)
        defaultTimerSeconds = clampedSeconds
        defaults.set(clampedSeconds, forKey: Keys.defaultTimerSeconds)
    }

    func setNewGameTeamNameDraft(_ draft: NewGameTeamNameDraft?) {
        newGameTeamNameDraft = draft

        guard let draft else {
            defaults.removeObject(forKey: Keys.newGameTeamNameDraft)
            return
        }

        let encoder = JSONEncoder()
        if let data = try? encoder.encode(draft) {
            defaults.set(data, forKey: Keys.newGameTeamNameDraft)
        }
    }
}

private extension AppSettingsStore {
    static func clampedRounds(_ rounds: Int) -> Int {
        min(max(rounds, 1), 10)
    }

    static func clampedTimerSeconds(_ seconds: Int) -> Int {
        let clamped = min(max(seconds, 30), 180)
        return (clamped / 5) * 5
    }

    static func loadTeamNameDraft(from defaults: UserDefaults) -> NewGameTeamNameDraft? {
        guard let data = defaults.data(forKey: Keys.newGameTeamNameDraft) else {
            return nil
        }

        let decoder = JSONDecoder()
        guard let draft = try? decoder.decode(NewGameTeamNameDraft.self, from: data) else {
            defaults.removeObject(forKey: Keys.newGameTeamNameDraft)
            return nil
        }

        return draft
    }
}
