import AVFoundation
import Foundation

enum CountdownTickStyle {
    case early
    case late
    case urgent
}

enum RevealSoundTier {
    case low
    case medium
    case high
}

protocol CountdownSoundPlaying {
    func playFinalCountdownTick(style: CountdownTickStyle, volume: Float)
    func playRoundEndedTone(volume: Float)
    func playRevealTone(tier: RevealSoundTier, volume: Float)
}

final class CountdownSoundService: CountdownSoundPlaying {
    private let earlyTickToneData: Data
    private let lateTickToneData: Data
    private let urgentTickToneData: Data
    private let roundEndedToneData: Data
    private let revealLowToneData: Data
    private let revealMediumToneData: Data
    private let revealHighToneData: Data
    private var activePlayers: [AVAudioPlayer] = []

    init() {
        earlyTickToneData = Self.makeToneData(
            frequency: 1_180,
            duration: 0.05,
            fadeOutDuration: 0.028
        )
        lateTickToneData = Self.makeToneData(
            frequency: 1_380,
            duration: 0.055,
            fadeOutDuration: 0.03
        )
        urgentTickToneData = Self.makeToneData(
            frequency: 1_640,
            duration: 0.06,
            fadeOutDuration: 0.032
        )
        roundEndedToneData = Self.makeToneSequenceData(
            [
                .init(frequency: 940, duration: 0.06, amplitude: 0.65),
                .init(frequency: 700, duration: 0.18, amplitude: 0.8)
            ],
            gapDuration: 0.018,
            fadeOutDuration: 0.08
        )
        revealLowToneData = Self.makeToneData(
            frequency: 720,
            duration: 0.055,
            fadeOutDuration: 0.032
        )
        revealMediumToneData = Self.makeToneSequenceData(
            [
                .init(frequency: 820, duration: 0.04, amplitude: 0.62),
                .init(frequency: 980, duration: 0.05, amplitude: 0.75)
            ],
            gapDuration: 0.01,
            fadeOutDuration: 0.035
        )
        revealHighToneData = Self.makeToneSequenceData(
            [
                .init(frequency: 900, duration: 0.04, amplitude: 0.58),
                .init(frequency: 1_120, duration: 0.045, amplitude: 0.7),
                .init(frequency: 1_340, duration: 0.05, amplitude: 0.82)
            ],
            gapDuration: 0.008,
            fadeOutDuration: 0.04
        )
        configureAudioSession()
    }

    func playFinalCountdownTick(style: CountdownTickStyle, volume: Float) {
        let toneData: Data
        switch style {
        case .early:
            toneData = earlyTickToneData
        case .late:
            toneData = lateTickToneData
        case .urgent:
            toneData = urgentTickToneData
        }
        playTone(toneData, volume: volume)
    }

    func playRoundEndedTone(volume: Float) {
        playTone(roundEndedToneData, volume: volume)
    }

    func playRevealTone(tier: RevealSoundTier, volume: Float) {
        let toneData: Data
        switch tier {
        case .low:
            toneData = revealLowToneData
        case .medium:
            toneData = revealMediumToneData
        case .high:
            toneData = revealHighToneData
        }
        playTone(toneData, volume: volume)
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
        amplitude: Double = 0.9,
        fadeOutDuration: Double,
        sampleRate: Double = 44_100
    ) -> Data {
        let pcmData = makePCMData(
            frequency: frequency,
            duration: duration,
            amplitude: amplitude,
            fadeOutDuration: fadeOutDuration,
            sampleRate: sampleRate
        )
        return makeWAVData(fromPCM16Mono: pcmData, sampleRate: Int(sampleRate))
    }

    private static func makeToneSequenceData(
        _ segments: [ToneSegment],
        gapDuration: Double,
        fadeOutDuration: Double,
        sampleRate: Double = 44_100
    ) -> Data {
        var pcmData = Data()

        for (index, segment) in segments.enumerated() {
            let segmentData = makePCMData(
                frequency: segment.frequency,
                duration: segment.duration,
                amplitude: segment.amplitude,
                fadeOutDuration: index == segments.indices.last ? fadeOutDuration : min(0.018, fadeOutDuration),
                sampleRate: sampleRate
            )
            pcmData.append(segmentData)

            if index != segments.indices.last, gapDuration > 0 {
                let gapFrames = max(1, Int(gapDuration * sampleRate))
                pcmData.append(Data(count: gapFrames * MemoryLayout<Int16>.size))
            }
        }

        return makeWAVData(fromPCM16Mono: pcmData, sampleRate: Int(sampleRate))
    }

    private static func makePCMData(
        frequency: Double,
        duration: Double,
        amplitude: Double,
        fadeOutDuration: Double,
        sampleRate: Double
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
            let signal = sin(2 * .pi * frequency * t) * envelope * amplitude
            let clampedSignal = max(-1, min(1, signal))
            var sample = Int16(clampedSignal * Double(Int16.max)).littleEndian
            withUnsafeBytes(of: &sample) { bytes in
                pcmData.append(contentsOf: bytes)
            }
        }

        return pcmData
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

private struct ToneSegment {
    let frequency: Double
    let duration: Double
    let amplitude: Double
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
