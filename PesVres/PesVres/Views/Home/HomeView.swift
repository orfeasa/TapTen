import SwiftUI

struct HomeView: View {
    let viewModel: HomeViewModel

    var body: some View {
        List {
            Section {
                NavigationLink("Start New Game") {
                    NewGameView(viewModel: NewGameViewModel())
                }

                NavigationLink("Game Flow Placeholder") {
                    GameFlowPlaceholderView()
                }
            }
        }
        .navigationTitle(viewModel.title)
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel())
    }
}
