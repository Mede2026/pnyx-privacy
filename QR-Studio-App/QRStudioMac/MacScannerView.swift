import AVFoundation
import AppKit
import QRCore
import SwiftUI

/// Scanner Mac : AVCaptureMetadataOutput (DataScannerViewController n'existe pas sur macOS).
/// La caméra peut être celle du Mac ou un iPhone via Caméra de continuité.
struct MacScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppServices.self) private var services
    @State private var scanner = CaptureScanner()
    @State private var devices: [AVCaptureDevice] = []
    @State private var deviceID: String?
    @State private var authorization = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var result: CodeEntry?
    @State private var recentPayloads: [String: Date] = [:]

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.black
                switch authorization {
                case .authorized:
                    if devices.isEmpty {
                        unavailable("Aucune caméra", "Branchez une caméra ou rapprochez votre iPhone pour utiliser Caméra de continuité.")
                    } else {
                        CameraPreview(scanner: scanner)
                    }
                case .notDetermined:
                    ProgressView()
                default:
                    VStack(spacing: 12) {
                        unavailable("Accès à la caméra désactivé",
                                    "Autorisez QR Studio dans Réglages Système › Confidentialité et sécurité › Caméra.")
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Camera") {
                            Button("Ouvrir Réglages Système") { NSWorkspace.shared.open(url) }
                        }
                    }
                }
            }
            .frame(minHeight: 360)

            if let result {
                MacScanResult(entry: result) {
                    self.result = nil
                    scanner.start()
                }
            }
        }
        .frame(minWidth: 640, minHeight: 520)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Fermer") { dismiss() }
            }
            ToolbarItem {
                Picker("Caméra", selection: $deviceID) {
                    ForEach(devices, id: \.uniqueID) { device in
                        Text(device.localizedName).tag(String?.some(device.uniqueID))
                    }
                }
                .frame(width: 240)
                .disabled(devices.count < 2)
            }
        }
        .task { await start() }
        .onChange(of: deviceID) { _, id in
            scanner.configure(deviceID: id)
            scanner.start()
        }
        .onDisappear { scanner.stop() }
        // Un iPhone qui s'approche (Caméra de continuité) ou une caméra branchée apparaît dans la liste.
        .onReceive(NotificationCenter.default.publisher(for: AVCaptureDevice.wasConnectedNotification)) { _ in
            devices = CaptureScanner.availableDevices()
        }
        .onReceive(NotificationCenter.default.publisher(for: AVCaptureDevice.wasDisconnectedNotification)) { _ in
            devices = CaptureScanner.availableDevices()
            if let deviceID, !devices.contains(where: { $0.uniqueID == deviceID }) {
                self.deviceID = CaptureScanner.defaultDevice()?.uniqueID
            }
        }
    }

    private func unavailable(_ title: LocalizedStringKey, _ detail: LocalizedStringKey) -> some View {
        ContentUnavailableView {
            Label(title, systemImage: "camera.metering.unknown")
        } description: {
            Text(detail)
        }
        .foregroundStyle(.white)
    }

    private func start() async {
        if authorization == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
            authorization = AVCaptureDevice.authorizationStatus(for: .video)
        }
        guard authorization == .authorized else { return }
        // Liste relue à chaque ouverture : on ne mémorise jamais une caméra.
        devices = CaptureScanner.availableDevices()
        deviceID = CaptureScanner.defaultDevice()?.uniqueID
        scanner.onObjects = { objects in handle(objects) }
        scanner.configure(deviceID: deviceID)
        scanner.start()
    }

    private func handle(_ objects: [AVMetadataMachineReadableCodeObject]) {
        guard result == nil, let object = objects.first, let payload = object.stringValue, !payload.isEmpty else { return }
        // Anti-doublon de 3 secondes.
        if let last = recentPayloads[payload], Date.now.timeIntervalSince(last) < 3 { return }
        recentPayloads[payload] = .now
        scanner.stop()
        NSSound(named: "Tink")?.play()
        result = services.store.recordScan(payload: payload, symbology: Symbology(metadataType: object.type))
    }
}
