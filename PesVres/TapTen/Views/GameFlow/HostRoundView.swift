import SwiftUI
import UIKit

struct HostRoundView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Bindable var viewModel: HostRoundViewModel
    let feedbackContext: QuestionFeedbackContext
    var hapticsEnabled = true
    var onRoundFinished: (() -> Void)? = nil
    @State private var pointsReactionText: String?
    @State private var isShowingPointsReaction = false
    @State private var isTimerPulsing = false
    @State private var isShowingFeedbackSheet = false
    @State private var feedbackFallbackMessage: String?

    var body: some View {
        GeometryReader { geometry in
            let containerHeight = geometry.size.height
            let sectionSpacing = dynamicTypeSize.isAccessibilitySize ? 8.0 : 6.0
            let rowSpacing = dynamicTypeSize.isAccessibilitySize ? 8.0 : 6.0
            let outerPadding = 14.0
            let controlsHeight = dynamicTypeSize.isAccessibilitySize ? 56.0 : 50.0
            let minimumRowHeight = dynamicTypeSize.isAccessibilitySize ? 38.0 : 30.0
            let minimumAnswersHeight = (minimumRowHeight * 10) + (rowSpacing * 9)
            let questionWidth = max(0, geometry.size.width - (outerPadding * 2))
            let questionHeaderHeight = measuredQuestionHeaderHeight(for: questionWidth)
            let timerSectionHeight = max(76, min(100, containerHeight * 0.12))
            let availableRowsHeight = containerHeight
                - (outerPadding * 2)
                - questionHeaderHeight
                - timerSectionHeight
                - controlsHeight
                - (sectionSpacing * 4)
            let fittedRowsHeight = max(minimumAnswersHeight, availableRowsHeight)
            let rowHeight = max(
                minimumRowHeight,
                (fittedRowsHeight - (rowSpacing * 9)) / 10
            )
            let answersHeight = (rowHeight * 10) + (rowSpacing * 9)

            VStack(spacing: sectionSpacing) {
                questionHeader
                    .frame(maxWidth: .infinity, minHeight: questionHeaderHeight, maxHeight: questionHeaderHeight, alignment: .topLeading)

                timerSection
                    .frame(maxWidth: .infinity, minHeight: timerSectionHeight, maxHeight: timerSectionHeight)

                VStack(spacing: rowSpacing) {
                    ForEach(sortedAnswerRows, id: \.offset) { index, answer in
                        HostAnswerRow(
                            title: answer.text,
                            points: answer.points,
                            isRevealed: viewModel.revealedAnswerIndices.contains(index),
                            rowHeight: rowHeight
                        ) {
                            viewModel.revealAnswer(at: index)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: answersHeight, alignment: .top)

                roundControls
                    .frame(maxWidth: .infinity, minHeight: controlsHeight, maxHeight: controlsHeight)
            }
            .padding(outerPadding)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .navigationTitle("Host Round")
        .navigationBarTitleDisplayMode(.inline)
        .background(hostRoundBackground)
        .tint(.tapTenPlayfulOrange)
        .sheet(isPresented: $isShowingFeedbackSheet) {
            HostRoundQuestionFeedbackSheet(
                context: feedbackContext,
                onSubmit: { composer in
                    guard let emailURL = composer.emailURL else {
                        UIPasteboard.general.string = composer.body
                        feedbackFallbackMessage = "Couldn't prepare the email draft. Feedback details were copied instead."
                        return
                    }

                    openURL(emailURL) { accepted in
                        if accepted {
                            isShowingFeedbackSheet = false
                            return
                        }

                        UIPasteboard.general.string = composer.body
                        feedbackFallbackMessage = "Couldn't open Mail. Feedback details were copied instead."
                    }
                }
            )
        }
        .alert("Feedback copied", isPresented: Binding(
            get: { feedbackFallbackMessage != nil },
            set: { isPresented in
                if !isPresented {
                    feedbackFallbackMessage = nil
                }
            }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(feedbackFallbackMessage ?? "")
        }
        .onAppear {
            viewModel.startRoundIfNeeded()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
        .onChange(of: viewModel.revealEventToken) {
            guard let points = viewModel.latestRevealPoints else {
                return
            }

            if hapticsEnabled {
                performRevealHaptic(for: points)
            }
            pointsReactionText = "+\(points)"
            withAnimation(.spring(response: 0.25, dampingFraction: 0.74)) {
                isShowingPointsReaction = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
                withAnimation(.easeOut(duration: 0.2)) {
                    isShowingPointsReaction = false
                }
            }
        }
        .onChange(of: viewModel.remainingTenths) { _, newValue in
            guard (1...100).contains(newValue), newValue.isMultiple(of: 10), !viewModel.isRoundFinished else {
                return
            }

            withAnimation(.easeInOut(duration: 0.12)) {
                isTimerPulsing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.easeOut(duration: 0.16)) {
                    isTimerPulsing = false
                }
            }
        }
    }

    private var questionHeader: some View {
        Text(viewModel.question.prompt)
            .font(.title.weight(.bold))
            .lineLimit(4)
            .minimumScaleFactor(0.55)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private var timerSection: some View {
        if viewModel.isRoundFinished {
            timeUpReviewSection
        } else {
            activeTimerSection
        }
    }

    private var activeTimerSection: some View {
        let countdownText = viewModel.formattedCountdown
        return VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Label(countdownText, systemImage: "timer")
                    .font(
                        .system(
                            size: dynamicTypeSize.isAccessibilitySize ? 28 : 32,
                            weight: .bold,
                            design: .rounded
                        )
                        .monospacedDigit()
                    )
                    .foregroundStyle(timerTextColor)
                    .scaleEffect(isTimerPulsing ? 1.03 : 1.0)

                Spacer()

                Text("\(viewModel.pointsAwarded) pts")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            ProgressView(
                value: viewModel.remainingTime,
                total: Double(viewModel.roundDurationSeconds)
            )
            .tint(timerProgressColor)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(alignment: .topTrailing) {
            if let pointsReactionText {
                Text(pointsReactionText)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color.tapTenRevealGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
                    .opacity(isShowingPointsReaction ? 1 : 0)
                    .offset(y: isShowingPointsReaction ? -12 : 0)
                    .allowsHitTesting(false)
            }
        }
    }

    private var timeUpReviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Label("Time's up", systemImage: "checkmark.circle.fill")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(Color.tapTenPlayfulOrange)

                Spacer()

                Text("\(viewModel.pointsAwarded) pts")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                Button {
                    openURL(viewModel.question.sourceURL)
                } label: {
                    Label("View Source", systemImage: "safari")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(.tapTenPlayfulBlue)

                Button {
                    isShowingFeedbackSheet = true
                } label: {
                    Label("Report Question", systemImage: "flag.badge.ellipsis")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.bordered)
                .tint(.tapTenPlayfulOrange)
            }
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var roundControls: some View {
        Group {
            if viewModel.isRoundFinished {
                Button {
                    onRoundFinished?()
                } label: {
                    Label("Continue to Summary", systemImage: "arrow.right.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 52)
                }
                .buttonStyle(TapTenPrimaryCapsuleButtonStyle())
            } else {
                HStack {
                    Spacer(minLength: 0)

                    Button {
                        viewModel.togglePause()
                    } label: {
                        Label(
                            viewModel.isPaused ? "Resume" : "Pause",
                            systemImage: viewModel.isPaused ? "play.fill" : "pause.fill"
                        )
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 18)
                        .frame(minWidth: 132, minHeight: 44)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(viewModel.isPaused ? Color.tapTenPlayfulOrange : .primary)
                    .background(.thinMaterial, in: Capsule(style: .continuous))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(
                                Color.tapTenPlayfulOrange.opacity(viewModel.isPaused ? 0.28 : 0.16),
                                lineWidth: 1
                            )
                    )

                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityHint(roundControlsAccessibilityHint)
    }

    private var roundControlsAccessibilityHint: String {
        viewModel.isRoundFinished
            ? "Continue to the round summary."
            : (viewModel.isPaused ? "Resume the round timer." : "Pause the round timer.")
    }

    private var timerProgressColor: Color {
        if viewModel.remainingTime <= 10 {
            return .red
        }

        let remainingRatio = viewModel.remainingTime / Double(viewModel.roundDurationSeconds)
        if remainingRatio <= 0.33 {
            return .orange
        }

        if remainingRatio <= 0.66 {
            return .yellow
        }

        return .tapTenRevealGreen
    }

    private var timerTextColor: Color {
        if viewModel.isRoundFinished || viewModel.remainingTime <= 10 {
            return .red
        }

        if viewModel.remainingTime <= 20 {
            return .orange
        }

        return .primary
    }

    private func performRevealHaptic(for points: Int) {
        if points >= 4 {
            let heavy = UIImpactFeedbackGenerator(style: .heavy)
            heavy.impactOccurred()
            let notify = UINotificationFeedbackGenerator()
            notify.notificationOccurred(.success)
            return
        }

        let style: UIImpactFeedbackGenerator.FeedbackStyle = points >= 2 ? .medium : .light
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    private var sortedAnswerRows: [(offset: Int, element: AnswerOption)] {
        Array(viewModel.question.answers.enumerated())
            .sorted { lhs, rhs in
                let comparison = lhs.element.text.localizedCaseInsensitiveCompare(rhs.element.text)
                if comparison == .orderedSame {
                    return lhs.offset < rhs.offset
                }
                return comparison == .orderedAscending
            }
    }

    private func measuredQuestionHeaderHeight(for width: CGFloat) -> CGFloat {
        let minimumHeight = dynamicTypeSize.isAccessibilitySize ? 74.0 : 56.0
        let maximumHeight = dynamicTypeSize.isAccessibilitySize ? 172.0 : 140.0
        let measuredHeight = viewModel.question.prompt
            .boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: questionHeaderFont],
                context: nil
            )
            .height
        let safetyBuffer = dynamicTypeSize.isAccessibilitySize ? 12.0 : 8.0

        return max(minimumHeight, min(maximumHeight, ceil(measuredHeight) + safetyBuffer))
    }

    private var questionHeaderFont: UIFont {
        let baseFont = UIFont.systemFont(ofSize: 28, weight: .bold)
        return UIFontMetrics(forTextStyle: .title1).scaledFont(for: baseFont)
    }
}

private struct HostRoundQuestionFeedbackSheet: View {
    @Environment(\.dismiss) private var dismiss

    let context: QuestionFeedbackContext
    let onSubmit: (QuestionFeedbackComposer) -> Void

    @State private var selectedReason: QuestionFeedbackReason = .tooEasy
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                questionDetailsSection
                commonReportsSection
                extraDetailsSection
                actionsSection
            }
            .navigationTitle("Report Question")
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

    private var canSubmit: Bool {
        selectedReason != .other || !trimmedNote.isEmpty
    }

    private var composer: QuestionFeedbackComposer {
        QuestionFeedbackComposer(
            context: context,
            reason: selectedReason,
            note: note
        )
    }

    private var trimmedNote: String {
        note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var sourceLabel: String {
        if let host = context.sourceURL.host(), !host.isEmpty {
            return host
        }

        return "Open source"
    }

    @ViewBuilder
    private var questionDetailsSection: some View {
        Section("Question Details") {
            VStack(alignment: .leading, spacing: 8) {
                Text(context.prompt)
                    .font(.body.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                LabeledContent("Category", value: context.category)
                    .font(.footnote)

                LabeledContent("Difficulty", value: context.difficultyTier.rawValue.capitalized)
                    .font(.footnote)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Source")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Link(destination: context.sourceURL) {
                        HStack(spacing: 8) {
                            Image(systemName: "safari")
                                .foregroundStyle(Color.tapTenPlayfulBlue)

                            Text(sourceLabel)
                                .font(.subheadline.weight(.semibold))
                                .lineLimit(1)
                        }
                    }

                    Text(context.sourceURL.absoluteString)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var commonReportsSection: some View {
        Section("Common Reports") {
            VStack(spacing: 0) {
                ForEach(Array(QuestionFeedbackReason.allCases.enumerated()), id: \.element.id) { index, reason in
                    reasonRow(reason)
                        .padding(.vertical, 12)

                    if index < QuestionFeedbackReason.allCases.count - 1 {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    @ViewBuilder
    private var extraDetailsSection: some View {
        Section(selectedReason == .other ? "Details Required" : "Extra Details") {
            VStack(alignment: .leading, spacing: 8) {
                Text(selectedReason == .other ? "Tell us what needs reviewing." : "Add context if it helps.")
                    .font(.subheadline.weight(.semibold))

                TextEditor(text: $note)
                    .frame(minHeight: 120)
            }
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        Section {
            VStack(spacing: 12) {
                Button {
                    onSubmit(composer)
                } label: {
                    Label("Open Report Email", systemImage: "envelope.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canSubmit)

                Button {
                    UIPasteboard.general.string = composer.body
                    dismiss()
                } label: {
                    Label("Copy Report Details", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!canSubmit)
            }
        }
    }

    @ViewBuilder
    private func reasonRow(_ reason: QuestionFeedbackReason) -> some View {
        Button {
            selectedReason = reason
        } label: {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(reason.title)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(reason.detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(selectedReason == reason ? Color.tapTenPlayfulOrange : Color.secondary.opacity(0.35))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(reason.title)
        .accessibilityValue(selectedReason == reason ? "Selected" : "Not selected")
    }
}

private struct HostAnswerRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    let points: Int
    let isRevealed: Bool
    let rowHeight: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isRevealed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isRevealed ? Color.tapTenRevealGreen : .secondary)
                    .font(.title3)

                Text(title)
                    .font(dynamicTypeSize.isAccessibilitySize ? .subheadline.weight(.semibold) : .body.weight(.medium))
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                    .minimumScaleFactor(0.55)
                    .allowsTightening(true)
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(points)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
            }
            .frame(maxWidth: .infinity, minHeight: rowHeight, maxHeight: rowHeight, alignment: .leading)
            .padding(.horizontal, 14)
            .background(rowBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isRevealed ? Color.tapTenRevealGreen.opacity(0.22) : .clear, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .scaleEffect(isRevealed ? 1.0 : 0.995)
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.22, dampingFraction: 0.8), value: isRevealed)
        .accessibilityLabel("\(title), \(points) points")
        .accessibilityValue(isRevealed ? "Revealed" : "Hidden")
        .accessibilityHint("Double tap to toggle this answer.")
    }

    private var rowBackground: some ShapeStyle {
        if isRevealed {
            return AnyShapeStyle(Color.tapTenRevealGreen.opacity(0.14))
        }

        return AnyShapeStyle(.background)
    }
}

private extension HostRoundView {
    var hostRoundBackground: some View {
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

    static func previewQuestion() -> Question {
        Question(
            id: "countries-starting-s",
            category: "Factual",
            prompt: "Name countries that start with the letter S",
            difficulty: .medium,
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

    static func previewFeedbackContext() -> QuestionFeedbackContext {
        let question = previewQuestion()
        return QuestionFeedbackContext(
            packID: "preview-pack",
            packTitle: "Preview Pack",
            packVersion: "1.0",
            questionID: question.id,
            prompt: question.prompt,
            category: question.category,
            difficultyTier: question.difficulty,
            validationStyle: question.validationStyle,
            sourceURL: question.sourceURL
        )
    }
}

#Preview("Default") {
    NavigationStack {
        HostRoundView(
            viewModel: HostRoundViewModel(
                question: HostRoundView.previewQuestion(),
                roundDurationSeconds: 60
            ),
            feedbackContext: HostRoundView.previewFeedbackContext()
        )
    }
}

#Preview("With Reveals") {
    NavigationStack {
        HostRoundView(
            viewModel: {
                let viewModel = HostRoundViewModel(
                    question: HostRoundView.previewQuestion(),
                    roundDurationSeconds: 60
                )
                viewModel.toggleAnswer(at: 0)
                viewModel.toggleAnswer(at: 4)
                viewModel.toggleAnswer(at: 9)
                return viewModel
            }(),
            feedbackContext: HostRoundView.previewFeedbackContext()
        )
    }
}

#Preview("Round Finished") {
    NavigationStack {
        HostRoundView(
            viewModel: {
                let viewModel = HostRoundViewModel(
                    question: HostRoundView.previewQuestion(),
                    roundDurationSeconds: 60
                )
                viewModel.toggleAnswer(at: 1)
                viewModel.endRound()
                return viewModel
            }(),
            feedbackContext: HostRoundView.previewFeedbackContext()
        )
    }
}
