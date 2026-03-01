import AudioToolbox
import Foundation

protocol CountdownSoundPlaying {
    func playFinalCountdownTick()
}

struct CountdownSoundService: CountdownSoundPlaying {
    private let soundID: SystemSoundID

    init(soundID: SystemSoundID = 1013) {
        self.soundID = soundID
    }

    func playFinalCountdownTick() {
        AudioServicesPlaySystemSound(soundID)
    }
}
