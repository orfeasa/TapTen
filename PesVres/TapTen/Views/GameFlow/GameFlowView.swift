import SwiftUI

struct GameFlowView: View {
    @State var viewModel: GameFlowViewModel

    var body: some View {
        Group {
            switch viewModel.phase {
            case .passDevice:
                PassDeviceView(
                    roundProgressText: viewModel.roundProgressText,
                    answeringTeamName: viewModel.answeringTeamName,
                    hostingTeamName: viewModel.hostingTeamName,
                    startAction: viewModel.startRound
                )

            case .hostRound:
                if let hostRoundViewModel = viewModel.hostRoundViewModel {
                    HostRoundView(
                        viewModel: hostRoundViewModel,
                        onRoundFinished: viewModel.finalizeActiveRoundIfNeeded
                    )
                } else {
                    flowErrorView(message: "Missing host round data.")
                }

            case .roundSummary:
                if let roundSummary = viewModel.latestRoundSummary {
                    RoundSummaryView(
                        summary: roundSummary,
                        teamAName: viewModel.teamAName,
                        teamAScore: viewModel.teamAScore,
                        teamBName: viewModel.teamBName,
                        teamBScore: viewModel.teamBScore,
                        continueTitle: viewModel.summaryContinueButtonTitle,
                        continueAction: viewModel.continueAfterRoundSummary
                    )
                } else {
                    flowErrorView(message: "Missing round summary data.")
                }

            case .finalResults:
                FinalResultsView(
                    winnerTitle: viewModel.winnerTitle,
                    winnerName: viewModel.winnerName,
                    teamAName: viewModel.teamAName,
                    teamAScore: viewModel.teamAScore,
                    teamBName: viewModel.teamBName,
                    teamBScore: viewModel.teamBScore
                )

            case .error(let message):
                flowErrorView(message: message)
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    @ViewBuilder
    private func flowErrorView(message: String) -> some View {
        ContentUnavailableView {
            Label("Game Flow Error", systemImage: "exclamationmark.triangle.fill")
        } description: {
            Text(message)
        }
        .navigationTitle("Game")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PassDeviceView: View {
    let roundProgressText: String
    let answeringTeamName: String
    let hostingTeamName: String
    let startAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            Text(roundProgressText)
                .font(.headline)
                .foregroundStyle(.secondary)

            VStack(spacing: 10) {
                Text("\(answeringTeamName) answers")
                    .font(.largeTitle.weight(.bold))
                    .multilineTextAlignment(.center)

                Text("Pass the phone to \(hostingTeamName), who will host this round.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)

            Spacer(minLength: 0)

            Button("Start Round", action: startAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .navigationTitle("Pass Device")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
}

private struct RoundSummaryView: View {
    let summary: GameFlowViewModel.RoundSummary
    let teamAName: String
    let teamAScore: Int
    let teamBName: String
    let teamBScore: Int
    let continueTitle: String
    let continueAction: () -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Round \(summary.roundNumber) Complete")
                    .font(.title2.weight(.bold))

                HStack(alignment: .top, spacing: 10) {
                    Text(summary.prompt)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Link(destination: summary.sourceURL) {
                        Image(systemName: "safari")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 36, height: 36)
                            .background(.background, in: Circle())
                    }
                    .accessibilityLabel("Open question source")
                }
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(spacing: 8) {
                    Text(summary.answeringTeamName)
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("+\(summary.pointsAwarded) points")
                        .font(.system(size: 42, weight: .black, design: .rounded))

                    Text("\(summary.revealedAnswers) of \(summary.totalAnswers) answers revealed")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(spacing: 0) {
                    Text(summary.sassyComment)
                        .font(.body.weight(.medium))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    scoreRow(name: teamAName, score: teamAScore)
                    scoreRow(name: teamBName, score: teamBScore)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button(continueTitle, action: continueAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .padding()
        }
        .navigationTitle("Round Summary")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }

    @ViewBuilder
    private func scoreRow(name: String, score: Int) -> some View {
        HStack {
            Text(name)
                .font(.headline)
            Spacer()
            Text("\(score)")
                .font(.title3.weight(.semibold))
        }
    }
}

private struct FinalResultsView: View {
    let winnerTitle: String
    let winnerName: String?
    let teamAName: String
    let teamAScore: Int
    let teamBName: String
    let teamBScore: Int

    @State private var celebrate = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            Image(systemName: winnerName == nil ? "person.3.fill" : "trophy.fill")
                .font(.system(size: 56, weight: .bold))
                .foregroundStyle(.yellow)
                .scaleEffect(celebrate ? 1.12 : 1.0)
                .animation(.spring(response: 0.45, dampingFraction: 0.55).repeatForever(autoreverses: true), value: celebrate)

            Text(winnerTitle)
                .font(.system(size: 44, weight: .black, design: .rounded))
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                scoreRow(name: teamAName, score: teamAScore)
                scoreRow(name: teamBName, score: teamBScore)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal)

            Spacer(minLength: 0)
        }
        .navigationTitle("Final Results")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.systemYellow).opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            celebrate = true
        }
    }

    @ViewBuilder
    private func scoreRow(name: String, score: Int) -> some View {
        HStack {
            Text(name)
                .font(.headline)
            Spacer()
            Text("\(score)")
                .font(.title3.weight(.bold))
        }
    }
}

private extension GameFlowView {
    static func previewQuestionPacks() -> [QuestionPack] {
        let sampleAnswers = [
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

        return [
            QuestionPack(
                id: "preview-pack",
                title: "Preview Pack",
                languageCode: "en",
                questions: [
                    Question(
                        id: "q1",
                        category: "Factual",
                        prompt: "Name countries that start with the letter S",
                        difficulty: .medium,
                        validationStyle: .factual,
                        sourceURL: URL(string: "https://example.com/q1")!,
                        answers: sampleAnswers
                    ),
                    Question(
                        id: "q2",
                        category: "Factual",
                        prompt: "Name common pizza toppings",
                        difficulty: .easy,
                        validationStyle: .editorial,
                        sourceURL: URL(string: "https://example.com/q2")!,
                        answers: sampleAnswers
                    )
                ]
            )
        ]
    }
}

#Preview("Pass Device") {
    NavigationStack {
        GameFlowView(
            viewModel: GameFlowViewModel(
                settings: GameSettings(teamAName: "Lions", teamBName: "Tigers", numberOfRounds: 2, roundDurationSeconds: 60),
                enabledCategoryNames: ["Factual"],
                questionPacks: GameFlowView.previewQuestionPacks(),
                randomIndexProvider: { _ in 0 }
            )
        )
    }
}

#Preview("Round Summary") {
    NavigationStack {
        RoundSummaryView(
            summary: GameFlowViewModel.RoundSummary(
                roundNumber: 2,
                prompt: "Name countries that start with the letter S",
                sourceURL: URL(string: "https://example.com/q2")!,
                sassyComment: "Solid showing. Mildly smug behavior is now permitted.",
                answeringTeamName: "Lions",
                pointsAwarded: 8,
                revealedAnswers: 5,
                totalAnswers: 10
            ),
            teamAName: "Lions",
            teamAScore: 14,
            teamBName: "Tigers",
            teamBScore: 11,
            continueTitle: "Pass Phone",
            continueAction: { }
        )
    }
}

#Preview("Final Results") {
    NavigationStack {
        FinalResultsView(
            winnerTitle: "LIONS WINS!",
            winnerName: "Lions",
            teamAName: "Lions",
            teamAScore: 41,
            teamBName: "Tigers",
            teamBScore: 35
        )
    }
}
