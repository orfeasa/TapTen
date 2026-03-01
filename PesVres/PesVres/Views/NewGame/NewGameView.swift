import SwiftUI

struct NewGameView: View {
    @State var viewModel: NewGameViewModel

    var body: some View {
        Form {
            Section("Teams") {
                TextField("Team A Name", text: $viewModel.settings.teamAName)
                TextField("Team B Name", text: $viewModel.settings.teamBName)
            }

            Section("Round Settings") {
                Stepper("Rounds: \(viewModel.settings.numberOfRounds)", value: $viewModel.settings.numberOfRounds, in: 1...10)
                Stepper("Duration: \(viewModel.settings.roundDurationSeconds)s", value: $viewModel.settings.roundDurationSeconds, in: 30...120, step: 10)
            }

            Section {
                NavigationLink("Continue to Game Flow") {
                    GameFlowPlaceholderView()
                }
            }
        }
        .navigationTitle("New Game")
    }
}

#Preview {
    NavigationStack {
        NewGameView(viewModel: NewGameViewModel())
    }
}
