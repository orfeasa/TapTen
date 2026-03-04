import Foundation
import Testing
@testable import TapTen

struct HostRoundViewModelTests {
    @Test
    func tapAgainUnrevealsAnswerDuringActiveRound() {
        let viewModel = HostRoundViewModel(
            question: makeQuestion(),
            roundDurationSeconds: 60
        )

        let firstReveal = viewModel.revealAnswer(at: 0)
        let secondReveal = viewModel.revealAnswer(at: 0)

        #expect(firstReveal == true)
        #expect(secondReveal == true)
        #expect(!viewModel.revealedAnswerIndices.contains(0))
        #expect(viewModel.pointsAwarded == 0)
    }

    @Test
    func togglingMultipleAnswersUpdatesPoints() {
        let viewModel = HostRoundViewModel(
            question: makeQuestion(),
            roundDurationSeconds: 60
        )

        _ = viewModel.revealAnswer(at: 0)
        _ = viewModel.revealAnswer(at: 2)
        #expect(viewModel.pointsAwarded == 4)

        _ = viewModel.revealAnswer(at: 2)
        #expect(viewModel.pointsAwarded == 1)

        _ = viewModel.revealAnswer(at: 0)
        #expect(viewModel.pointsAwarded == 0)
        #expect(viewModel.revealedAnswerIndices.isEmpty)
    }

    @Test
    func afterRoundEndsAnswersCanBeTickedAndUnticked() {
        let viewModel = HostRoundViewModel(
            question: makeQuestion(),
            roundDurationSeconds: 60
        )

        viewModel.endRound()

        let firstTap = viewModel.toggleAnswer(at: 1)
        #expect(firstTap == true)
        #expect(viewModel.revealedAnswerIndices.contains(1))

        let secondTap = viewModel.toggleAnswer(at: 1)
        #expect(secondTap == true)
        #expect(!viewModel.revealedAnswerIndices.contains(1))
    }

    @Test
    func countdownBoundaryFormattingIsStableAtTenSeconds() {
        let viewModel = makeDeterministicTimerViewModel(durationSeconds: 12)
        viewModel.startRoundIfNeeded()

        advanceTicks(viewModel, count: 9)
        #expect(viewModel.formattedCountdown == "11.1")

        advanceTicks(viewModel, count: 1)
        #expect(viewModel.formattedCountdown == "11.0")

        advanceTicks(viewModel, count: 1)
        #expect(viewModel.formattedCountdown == "10.9")

        advanceTicks(viewModel, count: 9)
        #expect(viewModel.formattedCountdown == "10.0")

        advanceTicks(viewModel, count: 1)
        #expect(viewModel.formattedCountdown == "9.9")

        advanceTicks(viewModel, count: 9)
        #expect(viewModel.formattedCountdown == "9.0")
    }

    @Test
    func countdownDisplayNeverIncreasesDuringRun() {
        let viewModel = makeDeterministicTimerViewModel(durationSeconds: 12)
        viewModel.startRoundIfNeeded()

        var previousTenths: Int = Int.max
        for _ in 0...160 {
            viewModel.processTickForTesting()

            let currentTenths = displayedTenths(from: viewModel.formattedCountdown)
            #expect(currentTenths <= previousTenths)
            previousTenths = currentTenths
        }
    }

    @Test
    func onceFinalPhaseStartsElevenNeverAppears() {
        let viewModel = makeDeterministicTimerViewModel(durationSeconds: 12)
        viewModel.startRoundIfNeeded()

        var seenFinalPhase = false
        for _ in 0...180 {
            viewModel.processTickForTesting()
            let display = viewModel.formattedCountdown

            if display.contains(".") {
                seenFinalPhase = true
            }

            if seenFinalPhase {
                #expect(display != "11")
            }
        }
    }

    @Test
    func countdownFinishesAtZeroAndStaysThere() {
        let viewModel = makeDeterministicTimerViewModel(durationSeconds: 1)
        viewModel.startRoundIfNeeded()

        advanceTicks(viewModel, count: 10)
        #expect(viewModel.isRoundFinished)
        #expect(viewModel.formattedCountdown == "0")

        advanceTicks(viewModel, count: 5)
        viewModel.processTickForTesting()
        #expect(viewModel.formattedCountdown == "0")
    }
}

private func makeQuestion() -> Question {
    Question(
        id: "host-round-test",
        category: "Factual",
        prompt: "Prompt",
        difficulty: .medium,
        validationStyle: .factual,
        sourceURL: URL(string: "https://example.com/source")!,
        answers: [
            AnswerOption(text: "A1", points: 1),
            AnswerOption(text: "A2", points: 2),
            AnswerOption(text: "A3", points: 3),
            AnswerOption(text: "A4", points: 4),
            AnswerOption(text: "A5", points: 5),
            AnswerOption(text: "A6", points: 1),
            AnswerOption(text: "A7", points: 1),
            AnswerOption(text: "A8", points: 1),
            AnswerOption(text: "A9", points: 1),
            AnswerOption(text: "A10", points: 1)
        ]
    )
}

private final class SilentCountdownPlayer: CountdownSoundPlaying {
    func playFinalCountdownTick(style: CountdownTickStyle, volume: Float) { }
    func playRoundEndedTone(volume: Float) { }
}

private func makeDeterministicTimerViewModel(durationSeconds: Int) -> HostRoundViewModel {
    HostRoundViewModel(
        question: makeQuestion(),
        roundDurationSeconds: durationSeconds,
        countdownSoundPlayer: SilentCountdownPlayer()
    )
}

private func displayedTenths(from formatted: String) -> Int {
    if formatted == "0" {
        return 0
    }

    if let dot = formatted.firstIndex(of: ".") {
        let secondsPart = Int(formatted[..<dot]) ?? 0
        let tenthsPart = Int(formatted[formatted.index(after: dot)...]) ?? 0
        return (secondsPart * 10) + tenthsPart
    }

    let seconds = Int(formatted) ?? 0
    return seconds * 10
}

private func advanceTicks(_ viewModel: HostRoundViewModel, count: Int) {
    for _ in 0..<count {
        viewModel.processTickForTesting()
    }
}
