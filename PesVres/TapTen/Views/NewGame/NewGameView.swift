import SwiftUI

struct NewGameView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: NewGameViewModel
    @State private var gameFlowViewModel: GameFlowViewModel?

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

                    Spacer()

                    Button("Exclude All") {
                        viewModel.excludeAllCategories()
                    }
                    .buttonStyle(.borderless)
                }
                .font(.subheadline)
            } header: {
                Text("Categories")
            } footer: {
                Text("\(viewModel.includedCategoryCount) selected")
            }

            Section {
                Button {
                    if viewModel.startGame() {
                        gameFlowViewModel = GameFlowViewModel(
                            settings: viewModel.settings,
                            enabledCategoryNames: viewModel.includedCategoryNames
                        )
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

            if let validationMessage = viewModel.validationMessage {
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
        .background(Color.tapTenWarmBackground)
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
