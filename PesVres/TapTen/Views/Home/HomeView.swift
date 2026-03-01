import SwiftUI

struct HomeView: View {
    let viewModel: HomeViewModel

    var body: some View {
        List {
            Section {
                NavigationLink("Start New Game") {
                    NewGameView(viewModel: NewGameViewModel())
                }

                NavigationLink("Host Round Preview") {
                    HostRoundView(
                        viewModel: HostRoundViewModel(
                            question: demoQuestion,
                            roundDurationSeconds: 60
                        )
                    )
                }
            }
        }
        .navigationTitle(viewModel.title)
    }

    private var demoQuestion: Question {
        Question(
            id: "countries-starting-s",
            category: "Factual",
            prompt: "Name countries that start with the letter S",
            validationStyle: .factual,
            sourceURL: URL(string: "https://en.wikipedia.org/wiki/List_of_sovereign_states")!,
            answers: [
                AnswerOption(text: "Spain", points: 1),
                AnswerOption(text: "Sweden", points: 1),
                AnswerOption(text: "Switzerland", points: 1),
                AnswerOption(text: "Serbia", points: 2),
                AnswerOption(text: "Slovakia", points: 2),
                AnswerOption(text: "Slovenia", points: 2),
                AnswerOption(text: "Singapore", points: 2),
                AnswerOption(text: "South Africa", points: 2),
                AnswerOption(text: "Sudan", points: 2),
                AnswerOption(text: "San Marino", points: 3)
            ]
        )
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel())
    }
}
