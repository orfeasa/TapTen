import SwiftUI

struct NewGameView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: NewGameViewModel
    @State private var gameFlowViewModel: GameFlowViewModel?
    @State private var startGameErrorMessage: String?

    var body: some View {
        Form {
            Section("Teams") {
                teamField(
                    title: "Team A",
                    placeholder: "Enter Team A name",
                    text: $viewModel.settings.teamAName
                )

                teamField(
                    title: "Team B",
                    placeholder: "Enter Team B name",
                    text: $viewModel.settings.teamBName
                )
            }

            Section("Round Settings") {
                Stepper(
                    "Rounds per Team: \(viewModel.settings.numberOfRounds)",
                    value: $viewModel.settings.numberOfRounds,
                    in: 1...10
                )

                Stepper(
                    "Round Timer: \(viewModel.settings.roundDurationSeconds) seconds",
                    value: $viewModel.settings.roundDurationSeconds,
                    in: 30...180,
                    step: 5
                )
            }

            Section {
                ForEach(viewModel.categories) { category in
                    Toggle(category.name, isOn: Binding(
                        get: { viewModel.isCategoryIncluded(category) },
                        set: { isIncluded in
                            viewModel.setCategory(category, included: isIncluded)
                        }
                    ))
                }

                HStack {
                    Button("Include All") {
                        viewModel.includeAllCategories()
                    }
                    .buttonStyle(.borderless)
                    .accessibilityHint("Turn on all categories.")

                    Spacer()

                    Button("Exclude All") {
                        viewModel.excludeAllCategories()
                    }
                    .buttonStyle(.borderless)
                    .accessibilityHint("Turn off all categories.")
                }
                .font(.subheadline)
            } header: {
                Text("Categories")
            } footer: {
                Text("\(viewModel.includedCategoryCount) selected")
            }

            Section {
                ForEach(QuestionDifficulty.allCases, id: \.self) { difficulty in
                    Toggle(difficulty.displayName, isOn: Binding(
                        get: { viewModel.isDifficultyIncluded(difficulty) },
                        set: { isIncluded in
                            viewModel.setDifficulty(difficulty, included: isIncluded)
                        }
                    ))
                }

                HStack {
                    Button("Include All") {
                        viewModel.includeAllDifficulties()
                    }
                    .buttonStyle(.borderless)
                    .accessibilityHint("Turn on all difficulty tiers.")

                    Spacer()

                    Button("Exclude All") {
                        viewModel.excludeAllDifficulties()
                    }
                    .buttonStyle(.borderless)
                    .accessibilityHint("Turn off all difficulty tiers.")
                }
                .font(.subheadline)
            } header: {
                Text("Difficulty")
            } footer: {
                Text("\(viewModel.includedDifficultyTiers.count) selected")
            }

            Section {
                Button {
                    if viewModel.startGame() {
                        let candidate = GameFlowViewModel(
                            settings: viewModel.settings,
                            enabledCategoryNames: viewModel.includedCategoryNames,
                            enabledDifficultyTiers: viewModel.includedDifficultyTiers,
                            soundsEnabled: AppSettingsStore.shared.soundsEnabled
                        )

                        if case .error(let message) = candidate.phase {
                            startGameErrorMessage = message
                            return
                        }

                        startGameErrorMessage = nil
                        gameFlowViewModel = candidate
                    }
                } label: {
                    Text("Start Game")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 46)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canStartGame)
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
            }

            if let validationMessage = viewModel.validationMessage ?? startGameErrorMessage {
                Section {
                    Text(validationMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
            }
        }
        .navigationTitle("New Game")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .background(newGameBackground)
        .navigationDestination(
            isPresented: Binding(
                get: { gameFlowViewModel != nil },
                set: { isPresented in
                    if !isPresented {
                        gameFlowViewModel = nil
                    }
                }
            )
        ) {
            if let gameFlowViewModel {
                GameFlowView(
                    viewModel: gameFlowViewModel,
                    onReturnHome: {
                        self.gameFlowViewModel = nil
                        dismiss()
                    }
                )
            }
        }
    }

    @ViewBuilder
    private func teamField(
        title: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(placeholder, text: text)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
        }
        .padding(.vertical, 2)
    }
}

private extension NewGameView {
    var newGameBackground: some View {
        ZStack(alignment: .top) {
            Color.tapTenWarmBackground

            LinearGradient(
                colors: [
                    Color.tapTenPlayfulOrange.opacity(0.11),
                    Color.tapTenPlayfulPink.opacity(0.08),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 250)
        }
        .ignoresSafeArea()
    }
}

private extension QuestionDifficulty {
    var displayName: String {
        rawValue.capitalized
    }
}

#Preview("Default") {
    NavigationStack {
        NewGameView(viewModel: NewGameViewModel())
    }
}

#Preview("Invalid Team Names") {
    NavigationStack {
        NewGameView(viewModel: {
            let vm = NewGameViewModel()
            vm.settings.teamAName = ""
            vm.settings.teamBName = "Team A"
            return vm
        }())
    }
}
