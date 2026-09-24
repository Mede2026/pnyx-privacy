#if canImport(AVFoundation) && !os(watchOS)
@preconcurrency import AVFoundation
import Foundation
import OSLog

/// Scanner AVFoundation (AVCaptureMetadataOutput) : repli iOS quand VisionKit n'est pas disponible,
/// et scanner principal sur Mac, où DataScannerViewController n'existe pas.
///
/// La session n'est modifiée que sur `sessionQueue` ; les codes détectés arrivent sur le fil principal.
public final class CaptureScanner: NSObject, @unchecked Sendable, AVCaptureMetadataOutputObjectsDelegate {
    public let session = AVCaptureSession()
    private let metadataOutput = AVCaptureMetadataOutput()
    private let sessionQueue = DispatchQueue(label: "app.qrstudio.capture")
    private var currentInput: AVCaptureDeviceInput?

    /// Objets détectés (coordonnées du flux vidéo), livrés sur le fil principal.
    @MainActor public var onObjects: (([AVMetadataMachineReadableCodeObject]) -> Void)?

    public override init() {
        super.init()
    }

    /// Caméras disponibles, recherchées à chaque appel : on ne suppose jamais leur position.
    public static func availableDevices() -> [AVCaptureDevice] {
        #if os(macOS)
        let types: [AVCaptureDevice.DeviceType] = [.builtInWideAngleCamera, .continuityCamera, .external]
        #else
        let types: [AVCaptureDevice.DeviceType] = [.builtInTripleCamera, .builtInDualWideCamera,
                                                   .builtInDualCamera, .builtInWideAngleCamera]
        #endif
        return AVCaptureDevice.DiscoverySession(deviceTypes: types, mediaType: .video, position: .unspecified).devices
    }

    /// Caméra par défaut : arrière sur iPhone et iPad, intégrée (ou Continuité) sur Mac.
    public static func defaultDevice() -> AVCaptureDevice? {
        let devices = availableDevices()
        #if os(macOS)
        // La caméra choisie par le système (souvent l'iPhone en Caméra de continuité quand il est proche).
        if let preferred = AVCaptureDevice.systemPreferredCamera, devices.contains(preferred) { return preferred }
        return devices.first
        #else
        return devices.first { $0.position == .back } ?? devices.first
        #endif
    }

    public func configure(deviceID: String? = nil) {
        sessionQueue.async { [self] in
            session.beginConfiguration()
            defer { session.commitConfiguration() }
            if let currentInput { session.removeInput(currentInput) }
            let device = deviceID.flatMap(AVCaptureDevice.init(uniqueID:)) ?? Self.defaultDevice()
            guard let device else {
                Logger.scanner.error("Aucune caméra disponible")
                return
            }
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                    currentInput = input
                }
            } catch {
                Logger.scanner.error("Caméra inutilisable : \(error.localizedDescription)")
                return
            }
            if !session.outputs.contains(metadataOutput), session.canAddOutput(metadataOutput) {
                session.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: .main)
            }
            // Tous les types de codes pris en charge par le matériel.
            metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
        }
    }

    public func start() {
        sessionQueue.async { [self] in
            if !session.isRunning { session.startRunning() }
        }
    }

    /// Arrête la session et coupe la torche en même temps.
    public func stop() {
        sessionQueue.async { [self] in
            if let device = currentInput?.device, device.hasTorch, device.torchMode == .on {
                do {
                    try device.lockForConfiguration()
                    device.torchMode = .off
                    device.unlockForConfiguration()
                } catch {
                    Logger.scanner.error("Torche non coupée : \(error.localizedDescription)")
                }
            }
            if session.isRunning { session.stopRunning() }
        }
    }

    public func metadataOutput(_ output: AVCaptureMetadataOutput,
                               didOutput metadataObjects: [AVMetadataObject],
                               from connection: AVCaptureConnection) {
        // La file du délégué est la file principale : les objets ne quittent jamais ce fil.
        nonisolated(unsafe) let codes = metadataObjects.compactMap { $0 as? AVMetadataMachineReadableCodeObject }
        MainActor.assumeIsolated {
            onObjects?(codes)
        }
    }
}

public extension Symbology {
    init(metadataType: AVMetadataObject.ObjectType) {
        switch metadataType {
        case .qr: self = .qr
        case .microQR: self = .microQR
        case .aztec: self = .aztec
        case .pdf417: self = .pdf417
        case .microPDF417: self = .microPDF417
        case .dataMatrix: self = .dataMatrix
        case .ean8: self = .ean8
        case .ean13: self = .ean13
        case .upce: self = .upcE
        case .code39, .code39Mod43: self = .code39
        case .code93: self = .code93
        case .code128: self = .code128
        case .itf14: self = .itf14
        case .interleaved2of5: self = .i2of5
        case .codabar: self = .codabar
        case .gs1DataBar: self = .gs1DataBar
        case .gs1DataBarExpanded: self = .gs1DataBarExpanded
        case .gs1DataBarLimited: self = .gs1DataBarLimited
        default: self = .unknown
        }
    }
}
#endif
