import SwiftUI

struct NewGameView: View {
    @State var viewModel: NewGameViewModel
    @State private var gameStartRequest: GameStartRequest?

    var body: some View {
        Form {
            Section("Teams") {
                TextField("Team A Name", text: $viewModel.settings.teamAName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()

                TextField("Team B Name", text: $viewModel.settings.teamBName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
            }

            Section("Round Settings") {
                Stepper(
                    "Number of Rounds: \(viewModel.settings.numberOfRounds)",
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
                Button("Start Game") {
                    if viewModel.startGame() {
                        gameStartRequest = GameStartRequest(
                            settings: viewModel.settings,
                            enabledCategoryNames: viewModel.includedCategoryNames
                        )
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .center)
                .disabled(!viewModel.canStartGame)
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
        .navigationDestination(item: $gameStartRequest) { request in
            GameFlowView(
                viewModel: GameFlowViewModel(
                    settings: request.settings,
                    enabledCategoryNames: request.enabledCategoryNames
                )
            )
        }
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
