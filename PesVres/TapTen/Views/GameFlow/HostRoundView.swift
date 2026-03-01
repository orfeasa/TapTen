import SwiftUI

struct HostRoundView: View {
    @State var viewModel: HostRoundViewModel
    var onRoundFinished: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            let containerHeight = geometry.size.height
            let sectionSpacing = 6.0
            let rowSpacing = 6.0
            let outerPadding = 14.0
            let buttonHeight = 58.0
            let minimumRowHeight = 30.0
            let minimumAnswersHeight = (minimumRowHeight * 10) + (rowSpacing * 9)
            let approximateQuestionLines = max(1, min(4, Int(ceil(Double(viewModel.question.prompt.count) / 28.0))))
            let questionHeaderHeight = max(56, min(116, 24 + (Double(approximateQuestionLines) * 22)))
            let timerSectionHeight = max(76, min(100, containerHeight * 0.12))
            let availableRowsHeight = containerHeight
                - (outerPadding * 2)
                - questionHeaderHeight
                - timerSectionHeight
                - buttonHeight
                - (sectionSpacing * 3)
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
                    ForEach(Array(viewModel.question.answers.enumerated()), id: \.offset) { index, answer in
                        HostAnswerRow(
                            title: answer.text,
                            points: answer.points,
                            isRevealed: viewModel.revealedAnswerIndices.contains(index),
                            rowHeight: rowHeight
                        ) {
                            viewModel.toggleAnswer(at: index)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: answersHeight, alignment: .top)

                bottomActionButton
                    .frame(maxWidth: .infinity, minHeight: buttonHeight, maxHeight: buttonHeight)
            }
            .padding(outerPadding)
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
        .navigationTitle("Host Round")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.startRoundIfNeeded()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }

    private var questionHeader: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(viewModel.question.prompt)
                .font(.title2.weight(.semibold))
                .lineLimit(4)
                .minimumScaleFactor(0.55)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if viewModel.isRoundFinished {
                Link(destination: viewModel.question.sourceURL) {
                    Image(systemName: "safari")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.blue)
                        .frame(width: 34, height: 34)
                        .background(.background, in: Circle())
                }
                .accessibilityLabel("Open question source")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Label(viewModel.formattedCountdown, systemImage: "timer")
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(viewModel.isRoundFinished ? .red : .primary)

                Spacer()

                Text("\(viewModel.pointsAwarded) pts")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if viewModel.isPaused && !viewModel.isRoundFinished {
                Text("Paused")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.orange)
            }

            ProgressView(
                value: viewModel.remainingTime,
                total: Double(viewModel.roundDurationSeconds)
            )
            .tint(timerProgressColor)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var bottomActionButton: some View {
        Button(bottomButtonTitle) {
            bottomButtonTapped()
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
    }

    private var bottomButtonTitle: String {
        if viewModel.isRoundFinished {
            return "Continue to Summary"
        }

        return viewModel.isPaused ? "Resume" : "Pause"
    }

    private func bottomButtonTapped() {
        if viewModel.isRoundFinished {
            onRoundFinished?()
            return
        }

        viewModel.togglePause()
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

        return .green
    }
}

private struct HostAnswerRow: View {
    let title: String
    let points: Int
    let isRevealed: Bool
    let rowHeight: Double
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isRevealed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isRevealed ? .green : .secondary)
                    .font(.title3)

                Text(title)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
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
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var rowBackground: some ShapeStyle {
        if isRevealed {
            return AnyShapeStyle(.green.opacity(0.16))
        }

        return AnyShapeStyle(.background)
    }
}

private extension HostRoundView {
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
