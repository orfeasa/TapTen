import SwiftUI

struct HostRoundView: View {
    @State var viewModel: HostRoundViewModel
    var onRoundFinished: (() -> Void)? = nil

    var body: some View {
        GeometryReader { geometry in
            let containerHeight = geometry.size.height
            let topSectionHeight = max(130, min(180, containerHeight * 0.23))
            let bottomSectionHeight = viewModel.isRoundFinished ? 92.0 : 58.0
            let verticalSpacing = 8.0
            let answerAreaHeight = max(
                360,
                containerHeight - topSectionHeight - bottomSectionHeight - 42
            )
            let rowHeight = max(
                36,
                min(56, (answerAreaHeight - (9 * verticalSpacing)) / 10)
            )

            VStack(spacing: 10) {
                topSection
                    .frame(maxWidth: .infinity, minHeight: topSectionHeight, maxHeight: topSectionHeight)

                VStack(spacing: verticalSpacing) {
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
                .frame(height: answerAreaHeight, alignment: .top)

                footerSection
            }
            .padding()
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

    private var topSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.question.prompt)
                .font(.headline.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .multilineTextAlignment(.leading)

            HStack(spacing: 12) {
                Label(viewModel.formattedCountdown, systemImage: "timer")
                    .font(.title2.monospacedDigit().weight(.bold))
                    .foregroundStyle(viewModel.isRoundFinished ? .red : .primary)

                Spacer()

                Text("\(viewModel.pointsAwarded) pts")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            ProgressView(
                value: Double(viewModel.remainingSeconds),
                total: Double(viewModel.roundDurationSeconds)
            )
            .tint(timerProgressColor)
        }
        .padding(14)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private var footerSection: some View {
        if viewModel.isRoundFinished {
            Button("Continue to Summary") {
                onRoundFinished?()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity, minHeight: 56)
        } else {
            Text("Timer running...")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 28)
        }
    }

    private var timerProgressColor: Color {
        if viewModel.remainingSeconds <= 10 {
            return .red
        }

        let remainingRatio = Double(viewModel.remainingSeconds) / Double(viewModel.roundDurationSeconds)
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
