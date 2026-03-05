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
        .background(settingsBackground)
    }
}

private extension SettingsView {
    var settingsBackground: some View {
        ZStack(alignment: .top) {
            Color.tapTenWarmBackground

            LinearGradient(
                colors: [
                    Color.tapTenPlayfulBlue.opacity(0.10),
                    Color.tapTenPlayfulViolet.opacity(0.07),
                    .clear
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .frame(height: 240)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    NavigationStack {
        SettingsView(settingsStore: AppSettingsStore())
    }
}
