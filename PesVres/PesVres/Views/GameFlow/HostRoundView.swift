import SwiftUI

struct HostRoundView: View {
    @State var viewModel: HostRoundViewModel
    var onRoundFinished: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.question.prompt)
                        .font(.title3.weight(.semibold))
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 12) {
                        Label(viewModel.formattedCountdown, systemImage: "timer")
                            .font(.title2.monospacedDigit().weight(.bold))

                        Spacer()

                        Text("\(viewModel.pointsAwarded) pts")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                    }

                    ProgressView(value: Double(viewModel.remainingSeconds), total: Double(viewModel.roundDurationSeconds))
                        .tint(viewModel.isRoundFinished ? .red : .accentColor)
                }
                .padding(16)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(spacing: 10) {
                    ForEach(Array(viewModel.question.answers.enumerated()), id: \.offset) { index, answer in
                        HostAnswerRow(
                            title: answer.text,
                            points: answer.points,
                            isRevealed: viewModel.revealedAnswerIndices.contains(index),
                            isRoundFinished: viewModel.isRoundFinished
                        ) {
                            viewModel.toggleAnswer(at: index)
                        }
                    }
                }
            }
            .padding()
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
        .onChange(of: viewModel.isRoundFinished) { _, isFinished in
            if isFinished {
                onRoundFinished?()
            }
        }
    }
}

private struct HostAnswerRow: View {
    let title: String
    let points: Int
    let isRevealed: Bool
    let isRoundFinished: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isRevealed ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isRevealed ? .green : .secondary)
                    .font(.title3)

                Text(title)
                    .font(.body.weight(.medium))
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(points)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .padding(.horizontal, 14)
            .background(rowBackground, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isRoundFinished)
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
