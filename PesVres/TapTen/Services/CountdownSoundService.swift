import AVFoundation
import Foundation

enum CountdownTickStyle {
    case click
    case beep
}

protocol CountdownSoundPlaying {
    func playFinalCountdownTick(style: CountdownTickStyle, volume: Float)
    func playRoundEndedTone(volume: Float)
}

final class CountdownSoundService: CountdownSoundPlaying {
    private let clickToneData: Data
    private let beepToneData: Data
    private let roundEndedToneData: Data
    private var activePlayers: [AVAudioPlayer] = []

    init() {
        clickToneData = Self.makeToneData(
            frequency: 1_900,
            duration: 0.035,
            fadeOutDuration: 0.025
        )
        beepToneData = Self.makeToneData(
            frequency: 920,
            duration: 0.12,
            fadeOutDuration: 0.05
        )
        roundEndedToneData = Self.makeToneData(
            frequency: 760,
            duration: 0.72,
            fadeOutDuration: 0.2
        )
        configureAudioSession()
    }

    func playFinalCountdownTick(style: CountdownTickStyle, volume: Float) {
        let toneData = style == .click ? clickToneData : beepToneData
        playTone(toneData, volume: volume)
    }

    func playRoundEndedTone(volume: Float) {
        playTone(roundEndedToneData, volume: volume)
    }

    private func playTone(_ toneData: Data, volume: Float) {
        do {
            let player = try AVAudioPlayer(data: toneData)
            player.volume = max(0, min(volume, 1))
            player.prepareToPlay()
            player.play()

            activePlayers.append(player)
            activePlayers.removeAll { !$0.isPlaying }
        } catch {
            // Keep gameplay unaffected if sound playback fails.
        }
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true, options: [])
        } catch {
            // If audio session setup fails, gameplay should continue silently.
        }
    }

    private static func makeToneData(
        frequency: Double,
        duration: Double,
        fadeOutDuration: Double,
        sampleRate: Double = 44_100
    ) -> Data {
        let frameCount = max(1, Int(duration * sampleRate))
        var pcmData = Data(capacity: frameCount * MemoryLayout<Int16>.size)

        for frame in 0..<frameCount {
            let t = Double(frame) / sampleRate
            let attack = min(1, t / 0.004)
            let releaseStart = max(0, duration - fadeOutDuration)
            let release: Double

            if t >= releaseStart {
                let remaining = max(0, duration - t)
                release = fadeOutDuration > 0 ? (remaining / fadeOutDuration) : 0
            } else {
                release = 1
            }

            let envelope = attack * min(1, release)
            let signal = sin(2 * .pi * frequency * t) * envelope * 0.9
            let clampedSignal = max(-1, min(1, signal))
            var sample = Int16(clampedSignal * Double(Int16.max)).littleEndian
            withUnsafeBytes(of: &sample) { bytes in
                pcmData.append(contentsOf: bytes)
            }
        }

        return makeWAVData(fromPCM16Mono: pcmData, sampleRate: Int(sampleRate))
    }

    private static func makeWAVData(fromPCM16Mono pcmData: Data, sampleRate: Int) -> Data {
        let numChannels: UInt16 = 1
        let bitsPerSample: UInt16 = 16
        let byteRate = UInt32(sampleRate) * UInt32(numChannels) * UInt32(bitsPerSample) / 8
        let blockAlign = UInt16(numChannels * (bitsPerSample / 8))
        let dataChunkSize = UInt32(pcmData.count)
        let riffChunkSize = UInt32(36) + dataChunkSize

        var wav = Data()
        wav.append("RIFF".data(using: .ascii)!)
        wav.appendLE(riffChunkSize)
        wav.append("WAVE".data(using: .ascii)!)

        wav.append("fmt ".data(using: .ascii)!)
        wav.appendLE(UInt32(16))
        wav.appendLE(UInt16(1))
        wav.appendLE(numChannels)
        wav.appendLE(UInt32(sampleRate))
        wav.appendLE(byteRate)
        wav.appendLE(blockAlign)
        wav.appendLE(bitsPerSample)

        wav.append("data".data(using: .ascii)!)
        wav.appendLE(dataChunkSize)
        wav.append(pcmData)

        return wav
    }
}

private extension Data {
    mutating func appendLE(_ value: UInt16) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { bytes in
            append(contentsOf: bytes)
        }
    }

    mutating func appendLE(_ value: UInt32) {
        var littleEndian = value.littleEndian
        Swift.withUnsafeBytes(of: &littleEndian) { bytes in
            append(contentsOf: bytes)
        }
    }
}
