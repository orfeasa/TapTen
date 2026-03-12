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

            Text("Good guesses. Fast taps.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            Text("One phone, two teams, one host under pressure. Keep rounds moving and trust your ears.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var currentSetupSummary: some View {
        VStack(spacing: 12) {
            Text("Current settings")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)

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
        .frame(maxWidth: .infinity, alignment: .center)
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
        setupSummaryChip(
            title: "2 teams",
            systemImage: "person.2.fill",
            tint: .tapTenPlayfulOrange
        )
    }

    var roundsChip: some View {
        setupSummaryChip(
            title: "\(settingsStore.defaultRounds) round\(settingsStore.defaultRounds == 1 ? "" : "s")",
            systemImage: "flag.fill",
            tint: .tapTenPlayfulPink
        )
    }

    var timerChip: some View {
        setupSummaryChip(
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

    func setupSummaryChip(
        title: String,
        systemImage: String,
        tint: Color
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.title2.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .center)
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            tint.opacity(0.12),
                            Color.white.opacity(0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .allowsHitTesting(false)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(tint.opacity(0.24), lineWidth: 1)
                .allowsHitTesting(false)
        )
    }
}

private struct HowToPlaySheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                HowToStepRow(
                    step: "1",
                    title: "Host holds the phone",
                    detail: "A player from the opposing team reads the prompt and handles all taps."
                )

                HowToStepRow(
                    step: "2",
                    title: "Guess out loud",
                    detail: "The answering team calls guesses while the host reveals matching answers."
                )

                HowToStepRow(
                    step: "3",
                    title: "Switch and repeat",
                    detail: "When time is up, review round results, swap host roles, and start the next turn."
                )
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
        }
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
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 1)
        }
        .padding(.vertical, 4)
    }
}

private struct PackBrowserView: View {
    @State private var packs: [QuestionPack] = []
    @State private var loadError: String?

    var body: some View {
        List {
            if let loadError {
                Section {
                    Text(loadError)
                        .foregroundStyle(.red)
                } header: {
                    Text("Unable to Load Packs")
                }
            } else {
                Section("Category Coverage") {
                    ForEach(categoryCoverage) { coverage in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(coverage.category)
                                    .font(.headline)
                                Spacer()
                                Text("\(coverage.total) questions")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            Text("Easy \(coverage.easy) • Medium \(coverage.medium) • Hard \(coverage.hard)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }

                Section("Packs") {
                    ForEach(packSummaries) { summary in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(summary.title)
                                .font(.headline)

                            Text("\(summary.questionCount) questions • \(summary.categoryList)")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .navigationTitle("Question Packs")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
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
