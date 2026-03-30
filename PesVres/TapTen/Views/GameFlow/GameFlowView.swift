import SwiftUI
import UIKit

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
                    startAction: viewModel.showQuestionPreview
                )

            case .questionPreview:
                QuestionPreviewView(
                    prompt: viewModel.currentQuestionPrompt,
                    roundDurationSeconds: viewModel.roundDurationSeconds,
                    startAction: viewModel.startRound
                )

            case .hostRound:
                if let hostRoundViewModel = viewModel.hostRoundViewModel {
                    HostRoundView(
                        viewModel: hostRoundViewModel,
                        feedbackContext: viewModel.currentQuestionFeedbackContext,
                        showsReviewUtilities: viewModel.currentQuestionShowsReviewUtilities,
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
                        soundsEnabled: settingsStore.soundsEnabled,
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
                    soundsEnabled: settingsStore.soundsEnabled,
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
                    .popover(
                        isPresented: $isShowingEndGameConfirmation,
                        attachmentAnchor: .rect(.bounds),
                        arrowEdge: .top
                    ) {
                        EndGameConfirmationPopover(
                            cancelAction: {
                                isShowingEndGameConfirmation = false
                            },
                            confirmAction: {
                                isShowingEndGameConfirmation = false
                                returnHome()
                            }
                        )
                    }
                    .accessibilityHint("End the current game and return to Home.")
                }
            }
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
        case .passDevice, .questionPreview, .hostRound, .roundSummary:
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

private struct EndGameConfirmationPopover: View {
    let cancelAction: () -> Void
    let confirmAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("End this game?")
                .font(.headline)

            Text("This will end the current game and return Home.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Cancel", action: cancelAction)
                    .buttonStyle(.bordered)

                Button("End Game", role: .destructive, action: confirmAction)
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
            }
        }
        .padding(18)
        .frame(width: 260)
        .presentationCompactAdaptation(.popover)
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
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 16) {
                roundBadge

                handoffBlock
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 20)
        .padding(.top, 28)
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

    private var handoffBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                        .foregroundStyle(Color.primary.opacity(0.68))
                }

                roleBlock(
                    label: "Guessing team",
                    value: answeringTeamName,
                    font: .system(.largeTitle, design: .rounded).weight(.black)
                )

                roleBlock(
                    label: "Phone holder",
                    value: hostingTeamName,
                    font: .title2.weight(.bold)
                )

                Text("Pass the phone to \(hostingTeamName). They read the prompt and tap answers as your team calls them out. No peeking.")
                    .font(.body)
                    .foregroundStyle(Color.primary.opacity(0.72))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)

            Divider()
                .padding(.horizontal, 20)

            Button(action: startAction) {
                Text("Show Question")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(TapTenPrimaryCapsuleButtonStyle())
            .padding(20)
        }
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
        .accessibilityHint("Pass the phone to the phone holder. They tap answers as the guessing team calls them out.")
    }

    private func roleBlock(label: String, value: String, font: Font) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.primary.opacity(0.62))

            Text(value)
                .font(font)
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.68)
                .lineLimit(2)
        }
    }

    var passDeviceBackground: some View {
        ZStack(alignment: .top) {
            Color.tapTenWarmBackground

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.tapTenPlayfulOrange.opacity(0.16),
                            Color.tapTenPlayfulPink.opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 12,
                        endRadius: 220
                    )
                )
                .frame(width: 380, height: 240)
                .blur(radius: 18)
                .offset(x: -64, y: -104)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.tapTenPlayfulPink.opacity(0.08),
                            Color.tapTenPlayfulViolet.opacity(0.06),
                            .clear
                        ],
                        center: .center,
                        startRadius: 12,
                        endRadius: 200
                    )
                )
                .frame(width: 340, height: 220)
                .blur(radius: 20)
                .offset(x: 92, y: -116)
        }
        .ignoresSafeArea()
    }
}

private struct QuestionPreviewView: View {
    let prompt: String
    let roundDurationSeconds: Int
    let startAction: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let containerHeight = geometry.size.height
            let containerWidth = geometry.size.width
            let sectionSpacing = 6.0
            let outerPadding = 14.0
            let questionWidth = max(0, containerWidth - (outerPadding * 2))
            let questionHeaderHeight = measuredQuestionHeaderHeight(for: questionWidth)
            let previewInfoHeight = max(88, min(116, containerHeight * 0.15))

            VStack(spacing: sectionSpacing) {
                questionHeader(for: questionWidth)
                    .frame(
                        maxWidth: .infinity,
                        minHeight: questionHeaderHeight,
                        maxHeight: questionHeaderHeight,
                        alignment: .topLeading
                    )

                previewInfoSection
                    .frame(maxWidth: .infinity, minHeight: previewInfoHeight, alignment: .top)

                Spacer(minLength: 0)

                Button(action: startAction) {
                    Text("Start Timer")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(TapTenPrimaryCapsuleButtonStyle())
            }
            .padding(outerPadding)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .navigationTitle("Question")
        .navigationBarTitleDisplayMode(.inline)
        .background(questionPreviewBackground)
    }

    private func questionHeader(for width: CGFloat) -> some View {
        Text(prompt)
            .font(questionHeaderFont(for: width))
            .lineLimit(4)
            .minimumScaleFactor(0.55)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var previewInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "timer")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("\(roundDurationSeconds)")
                        .font(.system(size: 32, weight: .bold, design: .rounded).monospacedDigit())
                        .foregroundStyle(.primary)
                }

                Spacer()

                Text("Ready")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Text("Take a moment to read it through. Start the timer only when the phone holder is ready.")
                .font(.footnote.weight(.medium))
                .foregroundStyle(Color.primary.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func measuredQuestionHeaderHeight(for width: CGFloat) -> CGFloat {
        let isCompactWidth = width < 382
        let minimumHeight = isCompactWidth ? 72.0 : 56.0
        let maximumHeight = isCompactWidth ? 172.0 : 148.0
        let measuredHeight = prompt
            .boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: questionHeaderUIFont(for: width)],
                context: nil
            )
            .height
        let safetyBuffer = isCompactWidth ? 14.0 : 10.0

        return max(minimumHeight, min(maximumHeight, ceil(measuredHeight) + safetyBuffer))
    }

    private func questionHeaderFont(for width: CGFloat) -> Font {
        .system(
            size: width < 382 ? 25 : 28,
            weight: .bold,
            design: .default
        )
    }

    private func questionHeaderUIFont(for width: CGFloat) -> UIFont {
        let baseSize: CGFloat = width < 382 ? 25 : 28
        let textStyle: UIFont.TextStyle = width < 382 ? .title2 : .title1
        let baseFont = UIFont.systemFont(ofSize: baseSize, weight: .bold)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: baseFont)
    }

    private var questionPreviewBackground: some View {
        ZStack(alignment: .top) {
            Color.tapTenWarmBackground

            LinearGradient(
                colors: [
                    Color.tapTenPlayfulMint.opacity(0.10),
                    Color.tapTenPlayfulBlue.opacity(0.07),
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
    let soundsEnabled: Bool
    let continueTitle: String
    let continueAction: () -> Void
    @State private var animateHero = false
    @State private var showVerdict = false
    @State private var soundPlayer = CountdownSoundService()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Round \(summary.roundNumber) Wrapped")
                    .font(.title2.weight(.bold))

                Text(summary.prompt)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
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

                VStack(spacing: 10) {
                    Label("Verdict", systemImage: "sparkles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.tapTenCelebrationGold)

                    Text(summary.sassyComment)
                        .font(.title3.weight(.bold))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
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

                Button(action: continueAction) {
                    Label(continueTitle, systemImage: "arrow.right.circle.fill")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(TapTenPrimaryCapsuleButtonStyle())
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
            if soundsEnabled {
                soundPlayer.playRoundPayoffTone(tier: payoffSoundTier, volume: 0.34)
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

    private var payoffSoundTier: RoundPayoffSoundTier {
        let totalAnswers = max(summary.totalAnswers, 1)
        let revealedRatio = Double(summary.revealedAnswers) / Double(totalAnswers)

        switch revealedRatio {
        case ..<0.2:
            return .weak
        case ..<0.7:
            return .solid
        default:
            return .strong
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
    let soundsEnabled: Bool
    let playAgainAction: () -> Void
    let homeAction: () -> Void

    @State private var celebrate = false
    @State private var showHero = false
    @State private var soundPlayer = CountdownSoundService()

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard
                scoreCard
                actionStack
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
            .overlay(alignment: .topTrailing) {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.tapTenCelebrationGold.opacity(0.18),
                                .clear
                            ],
                            center: .center,
                            startRadius: 12,
                            endRadius: 170
                        )
                    )
                    .frame(width: 260, height: 260)
                    .offset(x: 70, y: -40)
            }
            .ignoresSafeArea()
        )
        .onAppear {
            celebrate = true
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                showHero = true
            }
            if soundsEnabled {
                soundPlayer.playFinalResultsTone(outcome: finalResultsSoundOutcome, volume: 0.38)
            }
        }
    }

    private var heroCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.tapTenCelebrationGold.opacity(0.18))
                    .frame(width: 92, height: 92)

                Image(systemName: winnerName == nil ? "person.3.fill" : "trophy.fill")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundStyle(Color.tapTenCelebrationGold)
                    .scaleEffect(celebrate ? 1.05 : 1.0)
                    .animation(
                        .spring(response: 0.6, dampingFraction: 0.72).repeatForever(autoreverses: true),
                        value: celebrate
                    )
            }

            VStack(spacing: 8) {
                Text(winnerTitle)
                    .font(.system(.largeTitle, design: .rounded).weight(.black))
                    .minimumScaleFactor(0.62)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                Text(winnerSubtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

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
        .padding(.vertical, 26)
        .padding(.horizontal, 20)
        .background(
            LinearGradient(
                colors: [Color.tapTenCelebrationGold.opacity(0.26), Color.tapTenPlayfulPink.opacity(0.14)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.tapTenCelebrationGold.opacity(0.42), lineWidth: 1)
        )
        .shadow(color: Color.tapTenCelebrationGold.opacity(0.15), radius: 14, y: 7)
        .scaleEffect(showHero ? 1 : 0.97)
        .opacity(showHero ? 1 : 0.86)
    }

    private var scoreCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Final Score")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()

                Text(scoreSummary)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Color.tapTenPlayfulOrange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.tapTenPlayfulOrange.opacity(0.12), in: Capsule())
            }

            VStack(spacing: 10) {
                scoreRow(name: teamAName, score: teamAScore)
                scoreRow(name: teamBName, score: teamBScore)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            LinearGradient(
                colors: [Color.tapTenWarmCard, Color.tapTenWarmCard.opacity(0.86)],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.tapTenCelebrationGold.opacity(0.15), lineWidth: 1)
        )
    }

    private var actionStack: some View {
        VStack(spacing: 10) {
            Button(action: playAgainAction) {
                Label("Play Again", systemImage: "arrow.clockwise.circle.fill")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(TapTenPrimaryCapsuleButtonStyle())
            .accessibilityHint("Start a new game with the current setup values.")

            Button(action: homeAction) {
                Label("Home", systemImage: "house.fill")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 54)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .accessibilityHint("Return to the Home screen.")
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    private func scoreRow(name: String, score: Int) -> some View {
        let isWinner = winnerName == name

        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isWinner ? Color.tapTenCelebrationGold.opacity(0.2) : Color.secondary.opacity(0.10))
                    .frame(width: 34, height: 34)

                Image(systemName: rowSymbol(for: name, isWinner: isWinner))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(isWinner ? Color.tapTenCelebrationGold : .secondary)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.headline)
                    .foregroundStyle(isWinner || winnerName == nil ? .primary : .secondary)

                Text(rowStatus(for: name, isWinner: isWinner))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(isWinner ? Color.tapTenPlayfulOrange : .secondary)
            }

            Spacer()

            Text("\(score)")
                .font(.system(.title, design: .rounded).weight(.black))
                .foregroundStyle(isWinner || winnerName == nil ? .primary : .secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            rowBackground(for: name, isWinner: isWinner),
            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isWinner ? Color.tapTenCelebrationGold.opacity(0.24) : Color.clear, lineWidth: 1)
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

    private var scoreSummary: String {
        if let winnerName {
            return "\(winnerName) on top"
        }

        return "Dead even"
    }

    private func rowSymbol(for name: String, isWinner: Bool) -> String {
        if winnerName == nil {
            return name == teamAName ? "equal.circle.fill" : "equal.circle"
        }

        return isWinner ? "crown.fill" : "flag.fill"
    }

    private func rowStatus(for name: String, isWinner: Bool) -> String {
        if winnerName == nil {
            return "Still level"
        }

        return isWinner ? "Winner" : "Runner-up"
    }

    private func rowBackground(for name: String, isWinner: Bool) -> Color {
        if winnerName == nil {
            return Color.tapTenWarmCard.opacity(0.82)
        }

        return isWinner ? Color.tapTenCelebrationGold.opacity(0.22) : Color.tapTenWarmCard.opacity(0.7)
    }

    private var finalResultsSoundOutcome: FinalResultsSoundOutcome {
        winnerName == nil ? .tie : .winner
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
                totalAnswers: 10,
                feedbackContext: QuestionFeedbackContext(
                    packID: "preview-pack",
                    packTitle: "Preview Pack",
                    packVersion: "1.0",
                    questionID: "q2",
                    prompt: "Name countries that start with the letter S",
                    category: "Factual",
                    difficultyTier: .medium,
                    validationStyle: .factual,
                    sourceURL: URL(string: "https://example.com/q2")!
                )
            ),
            teamAName: "Lions",
            teamAScore: 14,
            teamBName: "Tigers",
            teamBScore: 11,
            soundsEnabled: true,
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
            soundsEnabled: true,
            playAgainAction: { },
            homeAction: { }
        )
    }
}
