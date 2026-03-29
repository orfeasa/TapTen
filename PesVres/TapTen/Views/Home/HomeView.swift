import SwiftUI

struct HomeView: View {
    let viewModel: HomeViewModel
    @AppStorage("hasShownHowToPlayOnFirstLaunch") private var hasShownHowToPlayOnFirstLaunch = false
    @State private var settingsStore = AppSettingsStore.shared
    @State private var isShowingHowToPlay = false
    @State private var isShowingNewGame = false
    @State private var hasHandledInitialHowToPlayPresentation = false

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
                    Image(systemName: "gearshape.fill")
                        .font(.body.weight(.semibold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(Color.primary.opacity(0.72))
                }
                .accessibilityLabel("Settings")
                .accessibilityHint("Open game defaults and feedback settings.")
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
        .onAppear {
            guard !hasHandledInitialHowToPlayPresentation else {
                return
            }

            hasHandledInitialHowToPlayPresentation = true

            guard !hasShownHowToPlayOnFirstLaunch else {
                return
            }

            isShowingHowToPlay = true
            hasShownHowToPlayOnFirstLaunch = true
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(viewModel: HomeViewModel())
    }
}

private extension HomeView {
    var header: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                title: "Browse Library",
                systemImage: "books.vertical.fill",
                tint: .tapTenPlayfulBlue,
                strokeTint: Color.tapTenPlayfulBlue.opacity(0.24)
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("View the included library and any premium expansions.")
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
    @State private var entitlementStore = QuestionPackEntitlementStore.shared
    @State private var storefront = QuestionPackStorefront.shared
    @State private var monetizationTelemetryStore = MonetizationTelemetryStore.shared

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
                    introductoryCopy

                    if let storeMessage = storefront.storeMessage {
                        informationalRow {
                            Text(storeMessage)
                                .font(.footnote)
                                .foregroundStyle(Color.primary.opacity(0.72))
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityHint("Informational only.")
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Premium Expansions")

                        if premiumPackSummaries.isEmpty {
                            informationalRow {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("No premium expansions are bundled yet.")
                                        .font(.headline)

                                    Text("When premium packs arrive, they will show up here as extra themed expansions. You will still choose categories from New Game.")
                                        .font(.footnote)
                                        .foregroundStyle(Color.primary.opacity(0.72))
                                }
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityHint("Informational only.")
                        } else {
                            ForEach(premiumPackSummaries) { summary in
                                informationalRow {
                                    packSummaryContent(summary)
                                }
                                .accessibilityElement(children: .combine)
                                .accessibilityHint("Informational only.")
                            }
                        }
                    }

                    baseGameLibraryCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !premiumPackSummaries.isEmpty && !storefront.isUsingTesterUnlocks {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await storefront.restorePurchases(for: packs)
                        }
                    } label: {
                        if storefront.isRestoringPurchases {
                            ProgressView()
                        } else {
                            Text("Restore")
                        }
                    }
                    .disabled(storefront.isRestoringPurchases)
                    .accessibilityHint("Restore previously purchased premium pack unlocks.")
                }
            }
        }
        .background(Color.tapTenWarmBackground)
        .task {
            guard packs.isEmpty, loadError == nil else {
                return
            }
            await loadPacks()
        }
    }

    private var introductoryCopy: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add more packs here, then play them from New Game.")
                .font(.subheadline.weight(.semibold))
        }
    }

    private var includedCategoryCoverage: [CategoryCoverage] {
        var countsByCategory: [String: CategoryCoverage] = [:]
        let includedQuestions = packs
            .filter { $0.access == .free }
            .flatMap(\.questions)

        for question in includedQuestions {
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

    private var baseGameLibraryCard: some View {
        informationalRow {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Base Game Library")

                if let librarySummary {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(librarySummary.includedPackCount) starter categories • \(librarySummary.includedQuestionCount) questions")
                            .font(.headline)

                        Text("Every starter category currently has 12 questions with a 4 easy / 4 medium / 4 hard split.")
                            .font(.subheadline)
                            .foregroundStyle(Color.primary.opacity(0.72))
                    }
                }

                categoryChipGrid

                Text("Premium expansions can later add new themed categories or more questions to the library, but they are not enabled separately from New Game.")
                    .font(.footnote)
                    .foregroundStyle(Color.primary.opacity(0.66))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityHint("Summary of the included base game library.")
    }

    private var categoryChipGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 140, maximum: 220), spacing: 8, alignment: .leading)
            ],
            alignment: .leading,
            spacing: 8
        ) {
            ForEach(includedCategoryCoverage) { coverage in
                VStack(alignment: .leading, spacing: 2) {
                    Text(coverage.category)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)

                    Text("\(coverage.total) questions")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(Color.primary.opacity(0.62))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.42), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                )
            }
        }
    }

    private var packSummaries: [PackSummary] {
        packs.map { pack in
            let categories = Set(pack.questions.map(\.category)).sorted()
            return PackSummary(
                id: pack.id,
                title: pack.title,
                summary: pack.summary,
                questionCount: pack.questions.count,
                categoryList: categories.joined(separator: ", "),
                access: pack.access,
                merchandisingLabel: pack.merchandisingLabel,
                bundleCount: pack.bundleProductIDs.count,
                availability: entitlementStore.availability(for: pack),
                actionState: storefront.actionState(for: pack)
            )
        }
        .sorted { $0.title < $1.title }
    }

    private var includedPackSummaries: [PackSummary] {
        packSummaries.filter { $0.access == .free }
    }

    private var premiumPackSummaries: [PackSummary] {
        packSummaries.filter { $0.access == .premium }
    }

    private func loadPacks() async {
        monetizationTelemetryStore.recordPackBrowserOpened()

        do {
            let loadedPacks = try QuestionPackLoader().loadAllPacks()
            packs = loadedPacks
            loadError = nil
            await storefront.refreshStoreData(for: loadedPacks)
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

    @ViewBuilder
    private func packSummaryContent(_ summary: PackSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(summary.title)
                    .font(.headline)

                Spacer()

                accessBadge(for: summary)
            }

            if let audienceLabel = summary.audienceLabel {
                Text(audienceLabel)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.58))
                    .textCase(.uppercase)
            }

            if let summaryText = summary.summary {
                Text(summaryText)
                    .font(.subheadline)
                    .foregroundStyle(Color.primary.opacity(0.78))
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(summary.categoryDescription)
                    .font(.footnote)
                    .foregroundStyle(Color.primary.opacity(0.72))

                Spacer()

                Text("\(summary.questionCount) questions")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.primary.opacity(0.62))
            }

            if let subtitle = summary.storeSubtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Color.primary.opacity(0.62))
            }

            if let storeMessage = summary.purchaseMessage {
                HStack(spacing: 10) {
                    Text(storeMessage)
                        .font(.caption)
                        .foregroundStyle(Color.primary.opacity(0.62))

                    Spacer(minLength: 0)

                    purchaseButton(for: summary)
                }
            }
        }
    }

    @ViewBuilder
    private func accessBadge(for summary: PackSummary) -> some View {
        let title = summary.stateBadgeTitle
        let tint = summary.badgeTint

        if let iconName = summary.badgeIconName {
            Label(title, systemImage: iconName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tint.opacity(0.10), in: Capsule(style: .continuous))
        } else {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(tint.opacity(0.10), in: Capsule(style: .continuous))
        }
    }

    @ViewBuilder
    private func purchaseButton(for summary: PackSummary) -> some View {
        switch summary.actionState {
        case .unavailable:
            EmptyView()
        case .purchasing:
            ProgressView()
                .controlSize(.small)
        case .testerUnlock:
            Button {
                guard let pack = packs.first(where: { $0.id == summary.id }) else {
                    return
                }

                Task {
                    await storefront.purchase(pack, availablePacks: packs)
                }
            } label: {
                Text("Unlock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.tapTenPlayfulBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.tapTenPlayfulBlue.opacity(0.10), in: Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
        case .ready(let price):
            Button {
                guard let pack = packs.first(where: { $0.id == summary.id }) else {
                    return
                }

                Task {
                    await storefront.purchase(pack, availablePacks: packs)
                }
            } label: {
                Text(price ?? "Buy")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.tapTenPlayfulPink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.tapTenPlayfulPink.opacity(0.10), in: Capsule(style: .continuous))
            }
            .buttonStyle(.plain)
        }
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

    private var librarySummary: LibrarySummary? {
        guard !includedCategoryCoverage.isEmpty else {
            return nil
        }

        return LibrarySummary(
            includedPackCount: includedPackSummaries.count,
            includedQuestionCount: includedPackSummaries.reduce(0) { $0 + $1.questionCount },
            premiumPackCount: premiumPackSummaries.count,
            premiumQuestionCount: premiumPackSummaries.reduce(0) { $0 + $1.questionCount }
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
    let summary: String?
    let questionCount: Int
    let categoryList: String
    let access: QuestionPackAccess
    let merchandisingLabel: String?
    let bundleCount: Int
    let availability: QuestionPackAvailability
    let actionState: QuestionPackStoreActionState

    var audienceLabel: String? {
        merchandisingLabel
    }

    var categoryDescription: String {
        guard access == .premium else {
            return categoryList
        }

        return "Adds category: \(categoryList)"
    }

    var storeSubtitle: String? {
        guard access == .premium else {
            return nil
        }

        if actionState == .testerUnlock {
            return "Tester build: unlocks locally without charge."
        }

        if bundleCount == 1 {
            return "Also included in 1 bundle"
        }

        if bundleCount > 1 {
            return "Also included in \(bundleCount) bundles"
        }

        return nil
    }

    var purchaseMessage: String? {
        guard access == .premium else {
            return nil
        }

        switch availability {
        case .included:
            return nil
        case .locked:
            if actionState == .testerUnlock {
                return "Unlock this pack for testing. It will then appear in New Game."
            }

            return "Buy this pack to add its questions to New Game."
        case .unlocked:
            return "Unlocked. Its questions are included in future games."
        }
    }

    var stateBadgeTitle: String {
        switch availability {
        case .included:
            return "Included"
        case .locked:
            return "Premium"
        case .unlocked:
            return "Unlocked"
        }
    }

    var badgeIconName: String? {
        switch availability {
        case .included:
            return "checkmark.circle.fill"
        case .locked:
            return nil
        case .unlocked:
            return "checkmark.seal.fill"
        }
    }

    var badgeTint: Color {
        switch availability {
        case .included:
            return .tapTenPlayfulOrange
        case .locked:
            return .tapTenPlayfulPink
        case .unlocked:
            return .tapTenPlayfulBlue
        }
    }
}

private struct LibrarySummary {
    let includedPackCount: Int
    let includedQuestionCount: Int
    let premiumPackCount: Int
    let premiumQuestionCount: Int
}
