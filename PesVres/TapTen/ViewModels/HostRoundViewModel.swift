import Foundation
import Observation

@Observable
final class HostRoundViewModel {
    let question: Question
    let roundDurationSeconds: Int
    private let countdownSoundPlayer: any CountdownSoundPlaying
    private let soundsEnabled: Bool

    private(set) var remainingTime: TimeInterval
    private(set) var remainingTenths: Int
    private(set) var isRoundFinished = false
    private(set) var isPaused = false
    private(set) var revealedAnswerIndices: Set<Int> = []
    private(set) var latestRevealPoints: Int?
    private(set) var revealEventToken = 0

    private var timer: DispatchSourceTimer?
    private var lastAnnouncedSecond: Int?

    init(
        question: Question,
        roundDurationSeconds: Int = 60,
        countdownSoundPlayer: any CountdownSoundPlaying = CountdownSoundService(),
        soundsEnabled: Bool = true
    ) {
        let initialTenths = max(roundDurationSeconds, 1) * 10
        self.question = question
        self.roundDurationSeconds = max(roundDurationSeconds, 1)
        self.countdownSoundPlayer = countdownSoundPlayer
        self.soundsEnabled = soundsEnabled
        self.remainingTenths = initialTenths
        self.remainingTime = TimeInterval(initialTenths) / 10
    }

    deinit {
        stopTimer()
    }

    var formattedCountdown: String {
        if isRoundFinished {
            return "0"
        }

        let clampedTenths = max(0, remainingTenths)
        if clampedTenths == 0 {
            return "0"
        }

        // Enter decimal mode one tick early so we never flash a plain integer
        // at the boundary before final-ten countdown feel.
        if clampedTenths <= 110 {
            let seconds = clampedTenths / 10
            let tenths = clampedTenths % 10
            return "\(seconds).\(tenths)"
        }

        let wholeSeconds = (clampedTenths + 9) / 10
        if wholeSeconds < 60 {
            return "\(wholeSeconds)"
        }

        let minutes = wholeSeconds / 60
        let seconds = wholeSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var remainingSeconds: Int {
        max(0, (remainingTenths + 9) / 10)
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

        lastAnnouncedSecond = remainingSeconds

        let source = DispatchSource.makeTimerSource(queue: .main)
        source.schedule(
            deadline: .now() + .milliseconds(100),
            repeating: .milliseconds(100),
            leeway: .milliseconds(20)
        )
        source.setEventHandler { [weak self] in
            self?.tick()
        }
        timer = source
        source.resume()
    }

    func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    func endRound() {
        remainingTenths = 0
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
    }

    @discardableResult
    func revealAnswer(at index: Int) -> Bool {
        guard question.answers.indices.contains(index) else {
            return false
        }

        if revealedAnswerIndices.contains(index) {
            revealedAnswerIndices.remove(index)
            return true
        }

        revealedAnswerIndices.insert(index)
        if !isRoundFinished {
            latestRevealPoints = question.answers[index].points
            revealEventToken += 1
        }
        return true
    }

    // Backward-compatible call-site name.
    @discardableResult
    func toggleAnswer(at index: Int) -> Bool {
        revealAnswer(at: index)
    }

    private func tick() {
        guard !isRoundFinished else {
            stopTimer()
            return
        }

        guard !isPaused else {
            return
        }

        guard remainingTenths > 0 else {
            return
        }

        remainingTenths -= 1
        remainingTime = Double(remainingTenths) / 10

        if remainingTenths == 0 {
            if soundsEnabled {
                countdownSoundPlayer.playRoundEndedTone(volume: 1.0)
            }
            endRound()
            return
        }

        playCountdownSoundIfNeeded()
    }

    private func playCountdownSoundIfNeeded() {
        let currentSecond = remainingSeconds
        guard currentSecond != lastAnnouncedSecond else {
            return
        }

        defer {
            lastAnnouncedSecond = currentSecond
        }

        guard soundsEnabled else {
            return
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

    // Test-only deterministic tick trigger.
    func processTickForTesting() {
        tick()
    }
}
