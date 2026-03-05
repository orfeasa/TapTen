import SwiftUI
import UIKit

struct HostRoundView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Bindable var viewModel: HostRoundViewModel
    var hapticsEnabled = true
    var onRoundFinished: (() -> Void)? = nil
    @State private var pointsReactionText: String?
    @State private var isShowingPointsReaction = false
    @State private var isTimerPulsing = false

    var body: some View {
        GeometryReader { geometry in
            let containerHeight = geometry.size.height
            let sectionSpacing = dynamicTypeSize.isAccessibilitySize ? 8.0 : 6.0
            let rowSpacing = dynamicTypeSize.isAccessibilitySize ? 8.0 : 6.0
            let outerPadding = 14.0
            let controlsHeight = dynamicTypeSize.isAccessibilitySize ? 56.0 : 50.0
            let minimumRowHeight = dynamicTypeSize.isAccessibilitySize ? 38.0 : 30.0
            let minimumAnswersHeight = (minimumRowHeight * 10) + (rowSpacing * 9)
            let approximateQuestionLines = max(1, min(4, Int(ceil(Double(viewModel.question.prompt.count) / 28.0))))
            let questionHeaderBase = dynamicTypeSize.isAccessibilitySize ? 34.0 : 24.0
            let questionHeaderLineHeight = dynamicTypeSize.isAccessibilitySize ? 26.0 : 22.0
            let questionHeaderHeight = max(
                dynamicTypeSize.isAccessibilitySize ? 74.0 : 56.0,
                min(132, questionHeaderBase + (Double(approximateQuestionLines) * questionHeaderLineHeight))
            )
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
        HStack(alignment: .top, spacing: 12) {
            Text(viewModel.question.prompt)
                .font(.title.weight(.bold))
                .lineLimit(4)
                .minimumScaleFactor(0.55)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if viewModel.isRoundFinished {
                Link(destination: viewModel.question.sourceURL) {
                    Image(systemName: "safari")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.tapTenPlayfulBlue)
                        .frame(width: 34, height: 34)
                        .background(.background, in: Circle())
                }
                .accessibilityLabel("Open question source")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var timerSection: some View {
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

    private var roundControls: some View {
        Button {
            if viewModel.isRoundFinished {
                onRoundFinished?()
            } else {
                viewModel.togglePause()
            }
        } label: {
            Label(
                viewModel.isRoundFinished
                    ? "Continue to Summary"
                    : (viewModel.isPaused ? "Resume" : "Pause"),
                systemImage: viewModel.isRoundFinished
                    ? "arrow.right.circle.fill"
                    : (viewModel.isPaused ? "play.fill" : "pause.fill")
            )
            .font(.subheadline.weight(.semibold))
            .frame(maxWidth: .infinity)
        }
        .controlSize(.large)
        .buttonStyle(.borderedProminent)
        .frame(maxWidth: .infinity)
        .accessibilityHint(
            viewModel.isRoundFinished
                ? "Continue to the round summary."
                : (viewModel.isPaused ? "Resume the round timer." : "Pause the round timer.")
        )
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
}

#Preview("Default") {
    NavigationStack {
        HostRoundView(
            viewModel: HostRoundViewModel(
                question: HostRoundView.previewQuestion(),
                roundDurationSeconds: 60
            )
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
            }()
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
            }()
        )
    }
}
