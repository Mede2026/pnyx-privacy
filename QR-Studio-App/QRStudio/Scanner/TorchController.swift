import AVFoundation
import OSLog
import QRCore

/// Torche de l'appareil. La caméra est recherchée à chaque appel, jamais mémorisée :
/// sur un appareil pliable, elle peut changer d'un écran à l'autre.
@MainActor
enum TorchController {
    private static var device: AVCaptureDevice? {
        CaptureScanner.availableDevices().first { $0.position == .back && $0.hasTorch && $0.isTorchAvailable }
    }

    static var isAvailable: Bool { device != nil }

    /// Allume la torche à l'intensité demandée (0,1 à 1), ou l'éteint.
    static func set(_ isOn: Bool, level: Float = 1) {
        guard let device else { return }
        do {
            try device.lockForConfiguration()
            if isOn {
                try device.setTorchModeOn(level: min(max(level, 0.1), AVCaptureDevice.maxAvailableTorchLevel))
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {
            Logger.scanner.error("Torche inutilisable : \(error.localizedDescription)")
        }
    }
}
