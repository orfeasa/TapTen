import Foundation
import Observation

@Observable
final class HostRoundViewModel {
    let question: Question
    let roundDurationSeconds: Int
    private let countdownSoundPlayer: any CountdownSoundPlaying

    private(set) var remainingTime: TimeInterval
    private(set) var isRoundFinished = false
    private(set) var isPaused = false
    private(set) var revealedAnswerIndices: Set<Int> = []

    private var timer: Timer?
    private var lastTickDate: Date?
    private var lastAnnouncedSecond: Int?

    init(
        question: Question,
        roundDurationSeconds: Int = 60,
        countdownSoundPlayer: any CountdownSoundPlaying = CountdownSoundService()
    ) {
        self.question = question
        self.roundDurationSeconds = max(roundDurationSeconds, 1)
        self.remainingTime = TimeInterval(max(roundDurationSeconds, 1))
        self.countdownSoundPlayer = countdownSoundPlayer
    }

    deinit {
        stopTimer()
    }

    var formattedCountdown: String {
        let clampedTime = max(0, remainingTime)
        if clampedTime == 0 {
            return "0"
        }

        // Show decimals only during the final 10 seconds.
        if clampedTime <= 10 {
            let totalTenths = Int((clampedTime * 10).rounded(.up))
            let seconds = totalTenths / 10
            let tenths = totalTenths % 10
            return "\(seconds).\(tenths)"
        }

        // For sub-minute times, avoid a "00:" prefix.
        let roundedSeconds = Int(ceil(clampedTime))
        if roundedSeconds < 60 {
            return "\(roundedSeconds)"
        }

        let minutes = roundedSeconds / 60
        let seconds = roundedSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var remainingSeconds: Int {
        max(0, Int(ceil(remainingTime)))
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

        lastTickDate = Date()
        lastAnnouncedSecond = Int(ceil(remainingTime))

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        lastTickDate = nil
    }

    func endRound() {
        remainingTime = 0
        isRoundFinished = true
        isPaused = false
        stopTimer()
    }

    func togglePause() {
        guard !isRoundFinished else {
            return
        }

        isPaused.toggle()
        lastTickDate = Date()
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

        guard !isPaused else {
            lastTickDate = Date()
            return
        }

        let now = Date()
        guard let lastTickDate else {
            self.lastTickDate = now
            return
        }

        let elapsed = now.timeIntervalSince(lastTickDate)
        self.lastTickDate = now

        remainingTime = max(0, remainingTime - elapsed)
        playCountdownSoundIfNeeded()

        if remainingTime <= 0 {
            countdownSoundPlayer.playRoundEndedTone(volume: 1.0)
            endRound()
        }
    }

    private func playCountdownSoundIfNeeded() {
        let currentSecond = max(0, Int(ceil(remainingTime)))
        guard currentSecond != lastAnnouncedSecond else {
            return
        }

        defer {
            lastAnnouncedSecond = currentSecond
        }

        guard (1...10).contains(currentSecond) else {
            return
        }

        // 10...5 uses the lower pitch, 4...1 uses the higher pitch.
        let style: CountdownTickStyle = currentSecond >= 5 ? .beep : .click
        let progress = Double(11 - currentSecond) / 10.0
        let volume = Float(0.22 + (progress * 0.78))
        countdownSoundPlayer.playFinalCountdownTick(style: style, volume: volume)
    }
}
