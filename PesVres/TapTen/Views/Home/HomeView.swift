import SwiftUI

struct HomeView: View {
    let viewModel: HomeViewModel
    @State private var settingsStore = AppSettingsStore.shared
    @State private var isShowingHowToPlay = false
    @State private var isShowingNewGame = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                currentSetupSummary
                startGameButton
                howToPlayButton
                browsePacksButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 28)
            .padding(.bottom, 24)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    SettingsView(settingsStore: settingsStore)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.tapTenPlayfulBlue)
                        .frame(width: 32, height: 32)
                }
                .accessibilityLabel("Settings")
            }
        }
        .sheet(isPresented: $isShowingHowToPlay) {
            HowToPlaySheet()
        }
        .navigationDestination(isPresented: $isShowingNewGame) {
            NewGameView(
                viewModel: NewGameViewModel(
                    settings: settingsStore.defaultGameSettings
                ),
                onReturnHome: {
                    isShowingNewGame = false
                }
            )
        }
        .background(homeBackground)
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel())
    }
}

private extension HomeView {
    var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            heroPill

            Text("Tap Ten")
                .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                .foregroundStyle(.primary)

            Text("One team guesses. One team hosts. Then you swap.")
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            Text("Guess the top ten answers before time runs out. The host taps matching answers as they’re said.")
                .font(.body)
                .foregroundStyle(Color.primary.opacity(0.72))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var currentSetupSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Game defaults")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.66))

                Text("Change these in Settings")
                    .font(.footnote)
                    .foregroundStyle(Color.primary.opacity(0.66))
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    teamsChip
                    roundsChip
                    timerChip
                }

                VStack(spacing: 10) {
                    teamsChip
                    roundsChip
                    timerChip
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var startGameButton: some View {
        Button {
            isShowingNewGame = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.title3.weight(.bold))
                    .frame(width: 24, height: 24)

                Text("Start New Game")
                    .font(.headline.weight(.semibold))
            }
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
                                    Color.tapTenPlayfulOrange.opacity(0.96),
                                    Color.tapTenPlayfulPink.opacity(0.86)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.white.opacity(0.42), lineWidth: 1)
            )
            .shadow(color: Color.tapTenPlayfulOrange.opacity(0.24), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start New Game")
        .accessibilityHint("Open game setup.")
    }

    var howToPlayButton: some View {
        Button {
            isShowingHowToPlay = true
        } label: {
            secondaryActionRow(
                title: "How To Play",
                systemImage: "questionmark.circle.fill",
                tint: .tapTenPlayfulOrange,
                strokeTint: Color.tapTenPlayfulOrange.opacity(0.26)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Open quick instructions in a sheet.")
    }

    var browsePacksButton: some View {
        NavigationLink {
            PackBrowserView()
        } label: {
            secondaryActionRow(
                title: "Browse Question Packs",
                systemImage: "books.vertical.fill",
                tint: .tapTenPlayfulBlue,
                strokeTint: Color.tapTenPlayfulBlue.opacity(0.24)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("View available categories and question counts.")
    }

    var teamsChip: some View {
        setupSummaryCard(
            title: "2 teams",
            systemImage: "person.2.fill",
            tint: .tapTenPlayfulOrange
        )
    }

    var roundsChip: some View {
        setupSummaryCard(
            title: "\(settingsStore.defaultRounds) round\(settingsStore.defaultRounds == 1 ? "" : "s")",
            systemImage: "flag.fill",
            tint: .tapTenPlayfulPink
        )
    }

    var timerChip: some View {
        setupSummaryCard(
            title: "\(settingsStore.defaultTimerSeconds) sec",
            systemImage: "timer",
            tint: .tapTenPlayfulBlue
        )
    }

    var homeBackground: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [
                    Color.tapTenWarmBackground,
                    Color(.systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.tapTenPlayfulOrange.opacity(0.22),
                            Color.yellow.opacity(0.10),
                            .clear
                        ],
                        center: .center,
                        startRadius: 12,
                        endRadius: 240
                    )
                )
                .frame(width: 420, height: 280)
                .blur(radius: 18)
                .offset(x: -84, y: -118)

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.tapTenPlayfulPink.opacity(0.16),
                            Color.tapTenPlayfulViolet.opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 12,
                        endRadius: 230
                    )
                )
                .frame(width: 400, height: 260)
                .blur(radius: 20)
                .offset(x: 96, y: -108)
        }
        .ignoresSafeArea()
    }

    var heroPill: some View {
        Label("Host-operated party game", systemImage: "sparkles")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(.ultraThinMaterial, in: Capsule(style: .continuous))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(Color.tapTenPlayfulPink.opacity(0.28), lineWidth: 1)
            )
    }

    func secondaryActionRow(
        title: String,
        systemImage: String,
        tint: Color,
        strokeTint: Color
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 24, height: 24)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 50)
        .padding(.horizontal, 14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.28),
                            .clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(strokeTint, lineWidth: 1)
                .allowsHitTesting(false)
        )
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    func setupSummaryCard(
        title: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 20, height: 20)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.leading)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .padding(.horizontal, 14)
        .background(Color.tapTenWarmCard.opacity(0.92), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                .allowsHitTesting(false)
        )
        .accessibilityElement(children: .combine)
    }
}

private struct HowToPlaySheet: View {
    @Environment(\.dismiss) private var dismiss
    private let steps: [(step: String, title: String, detail: String)] = [
        (
            "1",
            "Host holds the phone",
            "A player from the other team reads the prompt and taps answers as they are guessed."
        ),
        (
            "2",
            "Guess out loud",
            "The guessing team calls out answers while the host reveals matching ones on screen."
        ),
        (
            "3",
            "Swap and repeat",
            "When time is up, review the round, swap host roles, and start the next turn."
        )
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("One team guesses. One team hosts. Then you swap.")
                            .font(.headline.weight(.semibold))

                        Text("Three quick steps and you’re playing.")
                            .font(.subheadline)
                            .foregroundStyle(Color.primary.opacity(0.7))
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            HowToStepRow(
                                step: step.step,
                                title: step.title,
                                detail: step.detail
                            )

                            if index < steps.count - 1 {
                                Divider()
                                    .padding(.leading, 48)
                            }
                        }
                    }
                    .padding(18)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.tapTenPlayfulOrange.opacity(0.14), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .navigationTitle("How To Play")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .background(howToPlayBackground)
        }
    }

    private var howToPlayBackground: some View {
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
                .frame(width: 360, height: 240)
                .blur(radius: 18)
                .offset(x: -56, y: -96)
        }
        .ignoresSafeArea()
    }
}

private struct HowToStepRow: View {
    let step: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(step)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.primary)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    Circle()
                        .stroke(Color.tapTenPlayfulOrange.opacity(0.26), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary.opacity(0.7))
            }
            .padding(.top, 1)
        }
        .padding(.vertical, 12)
    }
}

private struct PackBrowserView: View {
    @State private var packs: [QuestionPack] = []
    @State private var loadError: String?

    var body: some View {
        ScrollView {
            if let loadError {
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("Unable to Load Packs")

                    Text(loadError)
                        .foregroundStyle(.red)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Browse what’s included in each category and difficulty mix.")
                        .font(.subheadline)
                        .foregroundStyle(Color.primary.opacity(0.72))

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Category Coverage")

                        ForEach(categoryCoverage) { coverage in
                            informationalRow {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                                        Text(coverage.category)
                                            .font(.headline)

                                        Spacer()

                                        Text("\(coverage.total) questions")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Color.primary.opacity(0.62))
                                    }

                                    Text("Easy \(coverage.easy) • Medium \(coverage.medium) • Hard \(coverage.hard)")
                                        .font(.footnote)
                                        .foregroundStyle(Color.primary.opacity(0.72))
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityHint("Informational only.")
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Packs")

                        ForEach(packSummaries) { summary in
                            informationalRow {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                                        Text(summary.title)
                                            .font(.headline)

                                        Spacer()

                                        Text("\(summary.questionCount) questions")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(Color.primary.opacity(0.62))
                                    }

                                    Text(summary.categoryList)
                                        .font(.footnote)
                                        .foregroundStyle(Color.primary.opacity(0.72))
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityHint("Informational only.")
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Question Packs")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.tapTenWarmBackground)
        .task {
            guard packs.isEmpty, loadError == nil else {
                return
            }
            loadPacks()
        }
    }

    private var categoryCoverage: [CategoryCoverage] {
        var countsByCategory: [String: CategoryCoverage] = [:]

        for question in packs.flatMap(\.questions) {
            var current = countsByCategory[question.category] ?? CategoryCoverage(category: question.category)
            current.total += 1
            switch question.difficultyTier {
            case .easy:
                current.easy += 1
            case .medium:
                current.medium += 1
            case .hard:
                current.hard += 1
            }
            countsByCategory[question.category] = current
        }

        return countsByCategory.values.sorted { $0.category < $1.category }
    }

    private var packSummaries: [PackSummary] {
        packs.map { pack in
            let categories = Set(pack.questions.map(\.category)).sorted()
            return PackSummary(
                id: pack.id,
                title: pack.title,
                questionCount: pack.questions.count,
                categoryList: categories.joined(separator: ", ")
            )
        }
        .sorted { $0.title < $1.title }
    }

    private func loadPacks() {
        do {
            packs = try QuestionPackLoader().loadAllPacks()
            loadError = nil
        } catch {
            loadError = error.localizedDescription
        }
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color.primary.opacity(0.62))
            .textCase(.uppercase)
    }

    private func informationalRow<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                Color.tapTenWarmCard.opacity(0.92),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}

private struct CategoryCoverage: Identifiable {
    let id: String
    let category: String
    var total: Int
    var easy: Int
    var medium: Int
    var hard: Int

    init(category: String) {
        self.id = category
        self.category = category
        self.total = 0
        self.easy = 0
        self.medium = 0
        self.hard = 0
    }
}

private struct PackSummary: Identifiable {
    let id: String
    let title: String
    let questionCount: Int
    let categoryList: String
}
