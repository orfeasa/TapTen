import SwiftUI

struct SettingsView: View {
    @Bindable var settingsStore: AppSettingsStore

    var body: some View {
        Form {
            Section("Feedback") {
                Toggle("Sounds", isOn: $settingsStore.soundsEnabled)
                Toggle("Haptics", isOn: $settingsStore.hapticsEnabled)
            }

            Section("New Game Defaults") {
                Stepper(
                    "Rounds per Team: \(settingsStore.defaultRounds)",
                    value: $settingsStore.defaultRounds,
                    in: 1...10
                )

                Stepper(
                    "Round Timer: \(settingsStore.defaultTimerSeconds) seconds",
                    value: $settingsStore.defaultTimerSeconds,
                    in: 30...180,
                    step: 5
                )
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(Color.tapTenWarmBackground)
    }
}

#Preview {
    NavigationStack {
        SettingsView(settingsStore: AppSettingsStore())
    }
}
