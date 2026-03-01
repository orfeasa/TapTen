import Foundation
import Observation

@Observable
final class HostRoundViewModel {
    let question: Question
    let roundDurationSeconds: Int
    private let countdownSoundPlayer: any CountdownSoundPlaying

    private(set) var remainingSeconds: Int
    private(set) var isRoundFinished = false
    private(set) var revealedAnswerIndices: Set<Int> = []

    private var timer: Timer?

    init(
        question: Question,
        roundDurationSeconds: Int = 60,
        countdownSoundPlayer: any CountdownSoundPlaying = CountdownSoundService()
    ) {
        self.question = question
        self.roundDurationSeconds = max(roundDurationSeconds, 1)
        self.remainingSeconds = max(roundDurationSeconds, 1)
        self.countdownSoundPlayer = countdownSoundPlayer
    }

    deinit {
        stopTimer()
    }

    var formattedCountdown: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var pointsAwarded: Int {
        revealedAnswerIndices.reduce(0) { partialResult, index in
            partialResult + question.answers[index].points
        }
    }

    func startRoundIfNeeded() {
        guard timer == nil, !isRoundFinished else {
            return
        }

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    func endRound() {
        remainingSeconds = 0
        isRoundFinished = true
        stopTimer()
    }

    func toggleAnswer(at index: Int) {
        guard question.answers.indices.contains(index) else {
            return
        }

        if revealedAnswerIndices.contains(index) {
            revealedAnswerIndices.remove(index)
        } else {
            revealedAnswerIndices.insert(index)
        }
    }

    private func tick() {
        guard !isRoundFinished else {
            stopTimer()
            return
        }

        if remainingSeconds > 0 {
            remainingSeconds -= 1
        }

        if (1...10).contains(remainingSeconds) {
            countdownSoundPlayer.playFinalCountdownTick()
        }

        if remainingSeconds == 0 {
            endRound()
        }
    }
}
