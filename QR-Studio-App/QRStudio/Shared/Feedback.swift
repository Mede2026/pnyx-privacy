import AudioToolbox
import Foundation
import OSLog
import UIKit

/// Vibrations et sons courts du scanner.
/// Les sons sont des bips synthétisés à la volée (aucun fichier audio embarqué) et
/// joués comme sons système : ils respectent le mode silencieux.
@MainActor
final class Feedback {
    enum Tone {
        case success
        case duplicate
    }

    private let settings: AppSettings
    private let notification = UINotificationFeedbackGenerator()
    private let impact = UIImpactFeedbackGenerator(style: .light)
    private var sounds: [Tone: SystemSoundID] = [:]

    init(settings: AppSettings) {
        self.settings = settings
    }

    func prepare() {
        notification.prepare()
        impact.prepare()
    }

    func success() {
        if settings.usesHaptics { notification.notificationOccurred(.success) }
        play(.success)
    }

    func batchAdded(isDuplicate: Bool) {
        if settings.usesHaptics { impact.impactOccurred() }
        play(isDuplicate ? .duplicate : .success)
    }

    func warning() {
        if settings.usesHaptics { notification.notificationOccurred(.warning) }
    }

    private func play(_ tone: Tone) {
        guard settings.playsSound else { return }
        if sounds[tone] == nil { sounds[tone] = makeSound(tone) }
        guard let id = sounds[tone] else { return }
        AudioServicesPlaySystemSound(id)
    }

    private func makeSound(_ tone: Tone) -> SystemSoundID? {
        let segments: [(frequency: Double, duration: Double)] = switch tone {
        case .success: [(1760, 0.07)]
        case .duplicate: [(660, 0.06), (0, 0.04), (660, 0.06)]
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("tone-\(tone).wav")
        do {
            try Self.wav(segments).write(to: url)
        } catch {
            Logger.scanner.error("Son non créé : \(error.localizedDescription)")
            return nil
        }
        var id: SystemSoundID = 0
        let status = AudioServicesCreateSystemSoundID(url as CFURL, &id)
        return status == kAudioServicesNoError ? id : nil
    }

    /// WAV PCM 16 bits mono, avec une enveloppe courte pour éviter les clics.
    private static func wav(_ segments: [(frequency: Double, duration: Double)]) -> Data {
        let rate = 44_100.0
        var samples: [Int16] = []
        for segment in segments {
            let count = Int(rate * segment.duration)
            for i in 0..<count {
                let t = Double(i) / rate
                let envelope = min(1, Double(i) / 200, Double(count - i) / 200)
                let value = segment.frequency > 0 ? sin(2 * .pi * segment.frequency * t) * envelope * 0.35 : 0
                samples.append(Int16(value * Double(Int16.max)))
            }
        }
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        let byteCount = UInt32(samples.count * 2)
        data.append(contentsOf: Array("RIFF".utf8)); append(36 + byteCount)
        data.append(contentsOf: Array("WAVEfmt ".utf8)); append(UInt32(16))
        append(UInt16(1)); append(UInt16(1)); append(UInt32(rate)); append(UInt32(rate * 2))
        append(UInt16(2)); append(UInt16(16))
        data.append(contentsOf: Array("data".utf8)); append(byteCount)
        for sample in samples { append(sample) }
        return data
    }
}
