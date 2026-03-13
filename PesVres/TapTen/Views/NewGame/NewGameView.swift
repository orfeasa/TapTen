import SwiftUI

struct NewGameView: View {
    @Environment(\.dismiss) private var dismiss
    @State var viewModel: NewGameViewModel
    var onReturnHome: (() -> Void)? = nil
    @State private var gameFlowViewModel: GameFlowViewModel?
    @State private var startGameErrorMessage: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    introHeader

                    sectionCard(
                        title: "Teams",
                        subtitle: "Name both sides before the guesses start.",
                        systemImage: "person.2.fill",
                        tint: .tapTenPlayfulOrange
                    ) {
                        VStack(spacing: 12) {
                            if viewModel.hasSuggestedTeamNames {
                                teamNameShuffleButton
                            }

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
                    }

                    sectionCard(
                        title: "Categories",
                        subtitle: "Pick the packs in play.",
                        systemImage: "books.vertical.fill",
                        tint: .tapTenPlayfulBlue,
                        badgeText: "\(viewModel.includedCategoryCount) selected"
                    ) {
                        VStack(spacing: 0) {
                            ForEach(Array(viewModel.categories.enumerated()), id: \.element.id) { index, category in
                                toggleRow(
                                    title: category.name,
                                    isOn: Binding(
                                        get: { viewModel.isCategoryIncluded(category) },
                                        set: { isIncluded in
                                            viewModel.setCategory(category, included: isIncluded)
                                        }
                                    ),
                                    showsDivider: index < viewModel.categories.count - 1
                                )
                            }

                            bulkToggleActions(
                                includeTitle: "Include All",
                                excludeTitle: "Exclude All",
                                includeAction: viewModel.includeAllCategories,
                                excludeAction: viewModel.excludeAllCategories
                            )
                        }
                    }

                    sectionCard(
                        title: "Difficulty",
                        subtitle: "Mix the easy wins with the risky ones.",
                        systemImage: "dial.medium.fill",
                        tint: .tapTenPlayfulPink,
                        badgeText: "\(viewModel.includedDifficultyTiers.count) selected"
                    ) {
                        VStack(spacing: 0) {
                            ForEach(Array(QuestionDifficulty.allCases.enumerated()), id: \.element) { index, difficulty in
                                toggleRow(
                                    title: difficulty.displayName,
                                    isOn: Binding(
                                        get: { viewModel.isDifficultyIncluded(difficulty) },
                                        set: { isIncluded in
                                            viewModel.setDifficulty(difficulty, included: isIncluded)
                                        }
                                    ),
                                    showsDivider: index < QuestionDifficulty.allCases.count - 1
                                )
                            }

                            bulkToggleActions(
                                includeTitle: "Include All",
                                excludeTitle: "Exclude All",
                                includeAction: viewModel.includeAllDifficulties,
                                excludeAction: viewModel.excludeAllDifficulties
                            )
                        }
                    }

                    if let validationMessage = viewModel.validationMessage ?? startGameErrorMessage {
                        validationCard(message: validationMessage)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 110)
            }

            bottomActionBar
        }
        .navigationTitle("New Game")
        .navigationBarTitleDisplayMode(.inline)
        .background(newGameBackground)
        .ignoresSafeArea(.container, edges: .bottom)
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
                        if let onReturnHome {
                            onReturnHome()
                        } else {
                            dismiss()
                        }
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
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.systemBackground).opacity(0.82), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.tapTenPlayfulOrange.opacity(0.14), lineWidth: 1)
                )
        }
        .padding(.vertical, 2)
    }
}

private extension NewGameView {
    var teamNameShuffleButton: some View {
        Button(action: viewModel.applyNextSuggestedTeamNames) {
            Label("Shuffle Names", systemImage: "shuffle")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.tapTenPlayfulOrange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.tapTenPlayfulOrange.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityHint("Fill both team name fields with a playful suggested matchup.")
    }

    var introHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Set the matchup")
                .font(.system(.title2, design: .rounded).weight(.bold))

            Text("Choose the teams, pick the packs, and decide how spicy you want the round mix.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var bottomActionBar: some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.08)

            startGameButton
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 8)
        }
        .background(Color.tapTenWarmBackground.opacity(0.96))
    }

    var startGameButton: some View {
        Button(action: startGame) {
            Text("Start Game")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background {
                    ZStack {
                        Capsule(style: .continuous)
                            .fill(.ultraThinMaterial)

                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.tapTenPlayfulOrange.opacity(viewModel.canStartGame ? 0.96 : 0.55),
                                        Color.tapTenPlayfulPink.opacity(viewModel.canStartGame ? 0.82 : 0.45)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.40), lineWidth: 1)
                )
                .shadow(color: Color.tapTenPlayfulOrange.opacity(viewModel.canStartGame ? 0.18 : 0), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.canStartGame)
    }

    var newGameBackground: some View {
        ZStack(alignment: .top) {
            Color.tapTenWarmBackground

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.tapTenPlayfulOrange.opacity(0.18),
                            Color.tapTenPlayfulPink.opacity(0.10),
                            .clear
                        ],
                        center: .center,
                        startRadius: 12,
                        endRadius: 240
                    )
                )
                .frame(width: 420, height: 280)
                .blur(radius: 18)
                .offset(x: -70, y: -110)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.tapTenPlayfulBlue.opacity(0.10),
                            Color.tapTenPlayfulViolet.opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 12,
                        endRadius: 220
                    )
                )
                .frame(width: 380, height: 250)
                .blur(radius: 20)
                .offset(x: 110, y: -120)
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    func sectionCard<Content: View>(
        title: String,
        subtitle: String,
        systemImage: String,
        tint: Color,
        badgeText: String? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                Label(title, systemImage: systemImage)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer(minLength: 8)

                if let badgeText {
                    Text(badgeText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(tint.opacity(0.12), in: Capsule())
                }
            }

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            content()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.tapTenWarmCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            tint.opacity(0.10),
                            Color.white.opacity(0.08)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(tint.opacity(0.18), lineWidth: 1)
        )
    }

    @ViewBuilder
    func toggleRow(
        title: String,
        isOn: Binding<Bool>,
        showsDivider: Bool
    ) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(.body.weight(.medium))
        }
        .padding(.vertical, 12)

        if showsDivider {
            Divider()
                .overlay(Color.primary.opacity(0.06))
        }
    }

    @ViewBuilder
    func bulkToggleActions(
        includeTitle: String,
        excludeTitle: String,
        includeAction: @escaping () -> Void,
        excludeAction: @escaping () -> Void
    ) -> some View {
        Divider()
            .overlay(Color.primary.opacity(0.06))
            .padding(.top, 2)

        HStack {
            Button(includeTitle, action: includeAction)
                .buttonStyle(.plain)
                .foregroundStyle(Color.tapTenPlayfulOrange)
                .accessibilityHint("Turn on all options in this section.")

            Spacer()

            Button(excludeTitle, action: excludeAction)
                .buttonStyle(.plain)
                .foregroundStyle(Color.tapTenPlayfulOrange)
                .accessibilityHint("Turn off all options in this section.")
        }
        .font(.subheadline.weight(.medium))
        .padding(.top, 12)
    }

    @ViewBuilder
    func validationCard(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red)

            Text(message)
                .font(.footnote)
                .foregroundStyle(.red)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.red.opacity(0.18), lineWidth: 1)
        )
    }

    private func startGame() {
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
