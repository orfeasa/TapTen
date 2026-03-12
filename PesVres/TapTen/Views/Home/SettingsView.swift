import SwiftUI

struct SettingsView: View {
    @Bindable var settingsStore: AppSettingsStore

    var body: some View {
        Form {
            Section("Audio & Haptics") {
                Toggle("Sounds", isOn: Binding(
                    get: { settingsStore.soundsEnabled },
                    set: { settingsStore.setSoundsEnabled($0) }
                ))

                Toggle("Haptics", isOn: Binding(
                    get: { settingsStore.hapticsEnabled },
                    set: { settingsStore.setHapticsEnabled($0) }
                ))
            }

            Section("New Game Defaults") {
                Stepper(
                    "Rounds per Team: \(settingsStore.defaultRounds)",
                    value: Binding(
                        get: { settingsStore.defaultRounds },
                        set: { settingsStore.setDefaultRounds($0) }
                    ),
                    in: 1...10
                )

                Stepper(
                    "Round Timer: \(settingsStore.defaultTimerSeconds) seconds",
                    value: Binding(
                        get: { settingsStore.defaultTimerSeconds },
                        set: { settingsStore.setDefaultTimerSeconds($0) }
                    ),
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
