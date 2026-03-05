import SwiftUI

struct GameFlowView: View {
    @Bindable var viewModel: GameFlowViewModel
    var settingsStore: AppSettingsStore = .shared
    var onReturnHome: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingEndGameConfirmation = false

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
                        hapticsEnabled: settingsStore.hapticsEnabled,
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
                    teamBScore: viewModel.teamBScore,
                    playAgainAction: viewModel.playAgain,
                    homeAction: returnHome
                )

            case .error(let message):
                flowErrorView(message: message)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if canShowEndGameButton {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End Game", role: .destructive) {
                        isShowingEndGameConfirmation = true
                    }
                    .accessibilityHint("End the current game and return to Home.")
                }
            }
        }
        .confirmationDialog(
            "End this game?",
            isPresented: $isShowingEndGameConfirmation,
            titleVisibility: .visible
        ) {
            Button("End Game", role: .destructive) {
                returnHome()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will end the current game and return Home.")
        }
        .tint(.tapTenPlayfulOrange)
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

    private var canShowEndGameButton: Bool {
        switch viewModel.phase {
        case .passDevice, .hostRound, .roundSummary:
            return true
        case .finalResults, .error:
            return false
        }
    }

    private func returnHome() {
        if let onReturnHome {
            onReturnHome()
            return
        }

        dismiss()
    }
}

private struct PassDeviceView: View {
    let roundProgressText: String
    let answeringTeamName: String
    let hostingTeamName: String
    let startAction: () -> Void
    @State private var showContent = false
    @State private var pulseIcon = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            roundBadge

            Spacer(minLength: 8)

            VStack(alignment: .leading, spacing: 14) {
                ritualCard
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                Button("Start Round", action: startAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }

            Spacer(minLength: 12)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .navigationTitle("Pass Device")
        .navigationBarTitleDisplayMode(.inline)
        .background(passDeviceBackground)
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                showContent = true
            }
            pulseIcon = true
        }
    }

    private var roundBadge: some View {
        HStack(spacing: 8) {
            Image(systemName: "flag.fill")
                .font(.subheadline.weight(.semibold))
            Text(roundProgressText)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(Color.tapTenPlayfulOrange)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.tapTenPlayfulOrange.opacity(0.16), in: Capsule())
    }

    private var ritualCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.tapTenPlayfulOrange)
                    .scaleEffect(pulseIcon ? 1.06 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.2).repeatForever(autoreverses: true),
                        value: pulseIcon
                    )

                Text("Handoff time")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Text("\(answeringTeamName) is up")
                .font(.system(.largeTitle, design: .rounded).weight(.black))
                .minimumScaleFactor(0.68)
                .lineLimit(2)

            Text("Phone holder: \(hostingTeamName)")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text("No peeking. Keep it honest.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color.tapTenPlayfulOrange.opacity(0.16), Color.tapTenWarmCard],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.tapTenPlayfulOrange.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(roundProgressText). \(answeringTeamName) is answering. \(hostingTeamName) should hold the phone. No peeking.")
    }

    var passDeviceBackground: some View {
        ZStack(alignment: .top) {
            Color.tapTenWarmBackground
            LinearGradient(
                colors: [
                    Color.tapTenPlayfulOrange.opacity(0.10),
                    Color.tapTenPlayfulPink.opacity(0.06),
                    .clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(height: 220)
        }
        .ignoresSafeArea()
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
    @State private var animateHero = false
    @State private var showVerdict = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Round \(summary.roundNumber) Wrapped")
                    .font(.title2.weight(.bold))

                HStack(alignment: .top, spacing: 10) {
                    Text(summary.prompt)
                        .font(.headline)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Link(destination: summary.sourceURL) {
                        Image(systemName: "safari")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(Color.tapTenPlayfulBlue)
                            .frame(width: 36, height: 36)
                            .background(.background, in: Circle())
                    }
                    .accessibilityLabel("Open question source")
                }
                .padding()
                .background(Color.tapTenWarmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(spacing: 8) {
                    Text(summary.answeringTeamName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text("+\(summary.pointsAwarded) points")
                        .font(.system(.largeTitle, design: .rounded).weight(.black))
                        .minimumScaleFactor(0.55)
                        .lineLimit(1)
                        .contentTransition(.numericText())

                    Text("\(summary.revealedAnswers) of \(summary.totalAnswers) answers found.")
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 18)
                .background(
                    LinearGradient(
                        colors: [Color.tapTenPlayfulOrange.opacity(0.24), Color.tapTenCelebrationGold.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.tapTenCelebrationGold.opacity(0.35), lineWidth: 1)
                )
                .shadow(color: Color.tapTenPlayfulOrange.opacity(0.12), radius: 14, y: 6)
                .scaleEffect(animateHero ? 1 : 0.97)
                .opacity(animateHero ? 1 : 0.88)

                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.tapTenCelebrationGold)

                    Text(summary.sassyComment)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(
                    LinearGradient(
                        colors: [Color.tapTenCelebrationGold.opacity(0.16), Color.tapTenPlayfulOrange.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.tapTenCelebrationGold.opacity(0.24), lineWidth: 1)
                )
                .opacity(showVerdict ? 1 : 0)
                .offset(y: showVerdict ? 0 : 6)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Match Score")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    scoreRow(name: teamAName, score: teamAScore)
                    scoreRow(name: teamBName, score: teamBScore)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.tapTenWarmCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button(continueTitle, action: continueAction)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .padding()
        }
        .navigationTitle("Round Summary")
        .navigationBarTitleDisplayMode(.inline)
        .background(roundSummaryBackground)
        .onAppear {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.8)) {
                animateHero = true
            }
            withAnimation(.easeOut(duration: 0.24).delay(0.08)) {
                showVerdict = true
            }
        }
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

    var roundSummaryBackground: some View {
        ZStack(alignment: .top) {
            Color.tapTenWarmBackground
            LinearGradient(
                colors: [
                    Color.tapTenCelebrationGold.opacity(0.14),
                    Color.tapTenPlayfulViolet.opacity(0.06),
                    .clear
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            .frame(height: 220)
        }
        .ignoresSafeArea()
    }
}

private struct FinalResultsView: View {
    let winnerTitle: String
    let winnerName: String?
    let teamAName: String
    let teamAScore: Int
    let teamBName: String
    let teamBScore: Int
    let playAgainAction: () -> Void
    let homeAction: () -> Void

    @State private var celebrate = false
    @State private var showHero = false

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 12) {
                    Image(systemName: winnerName == nil ? "person.3.fill" : "trophy.fill")
                        .font(.system(size: 62, weight: .bold))
                        .foregroundStyle(Color.tapTenCelebrationGold)
                        .scaleEffect(celebrate ? 1.05 : 1.0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.72).repeatForever(autoreverses: true),
                            value: celebrate
                        )

                    Text(winnerTitle)
                        .font(.system(.largeTitle, design: .rounded).weight(.black))
                        .minimumScaleFactor(0.62)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)

                    Text(winnerSubtitle)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if let winningMargin {
                        Text("Won by \(winningMargin) point\(winningMargin == 1 ? "" : "s")")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.regularMaterial, in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 18)
                .background(
                    LinearGradient(
                        colors: [Color.tapTenCelebrationGold.opacity(0.28), Color.tapTenPlayfulPink.opacity(0.14)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 22, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(Color.tapTenCelebrationGold.opacity(0.45), lineWidth: 1)
                )
                .shadow(color: Color.tapTenCelebrationGold.opacity(0.15), radius: 14, y: 7)
                .scaleEffect(showHero ? 1 : 0.97)
                .opacity(showHero ? 1 : 0.86)

                VStack(alignment: .leading, spacing: 10) {
                    Text("Final Score")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    scoreRow(name: teamAName, score: teamAScore)
                    scoreRow(name: teamBName, score: teamBScore)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    LinearGradient(
                        colors: [Color.tapTenWarmCard, Color.tapTenWarmCard.opacity(0.86)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.tapTenCelebrationGold.opacity(0.15), lineWidth: 1)
                )

                VStack(spacing: 10) {
                    Button("Play Again", action: playAgainAction)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, minHeight: 56)
                        .accessibilityHint("Start a new game with current setup values.")

                    Button("Start New Game", action: homeAction)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .accessibilityHint("Return to game setup.")
                }
                .padding(.top, 2)
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 24)
        }
        .navigationTitle("Final Results")
        .navigationBarTitleDisplayMode(.inline)
        .background(
            LinearGradient(
                colors: [Color.tapTenWarmBackground, Color.tapTenCelebrationGold.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onAppear {
            celebrate = true
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showHero = true
            }
        }
    }

    @ViewBuilder
    private func scoreRow(name: String, score: Int) -> some View {
        let isWinner = winnerName == name

        HStack(spacing: 10) {
            Image(systemName: isWinner ? "crown.fill" : "circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isWinner ? Color.tapTenCelebrationGold : .secondary)

            Text(name)
                .font(.headline)
                .foregroundStyle(isWinner ? .primary : .secondary)

            Spacer()

            Text(isWinner ? "Winner" : "Runner-up")
                .font(.caption.weight(.semibold))
                .foregroundStyle(isWinner ? .primary : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    isWinner ? Color.tapTenCelebrationGold.opacity(0.28) : Color.secondary.opacity(0.12),
                    in: Capsule()
                )

            Text("\(score)")
                .font(.title2.weight(.black))
                .foregroundStyle(isWinner ? .primary : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            isWinner
                ? Color.tapTenCelebrationGold.opacity(0.22)
                : Color.tapTenWarmCard.opacity(0.7),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
    }

    private var winnerSubtitle: String {
        if winnerName == nil {
            return "Perfect stalemate. Nobody blinks."
        }

        return "Take a bow. That was tidy."
    }

    private var winningMargin: Int? {
        guard winnerName != nil else {
            return nil
        }

        return abs(teamAScore - teamBScore)
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
                sassyComment: "Strong round. Clean work.",
                answeringTeamName: "Lions",
                pointsAwarded: 8,
                revealedAnswers: 5,
                totalAnswers: 10
            ),
            teamAName: "Lions",
            teamAScore: 14,
            teamBName: "Tigers",
            teamBScore: 11,
            continueTitle: "Next Round",
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
            teamBScore: 35,
            playAgainAction: { },
            homeAction: { }
        )
    }
}
