import AVFoundation
import PhotosUI
import QRCore
import SwiftUI
import VisionKit

/// Écran d'accueil de l'app : la caméra démarre dès l'ouverture, sans bouton intermédiaire.
struct ScannerView: View {
    @Environment(ScannerModel.self) private var model
    @Environment(AppSettings.self) private var settings
    @Environment(AlertCenter.self) private var alerts
    @Environment(AppServices.self) private var services
    @State private var availability: CameraAvailability = .checking
    @State private var zoomRange: ClosedRange<Double> = 1...1
    @State private var photoItem: PhotosPickerItem?
    @State private var isPickingPhoto = false
    @State private var actions = ActionHandler()

    var body: some View {
        @Bindable var model = model
        ZStack {
            camera
                .ignoresSafeArea()

            if model.sweep == nil, availability.isLive {
                ViewfinderCorners()
                    .stroke(.white.opacity(0.85), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    .frame(width: 240, height: 240)
                    .shadow(color: .black.opacity(0.3), radius: 4)
                    .accessibilityHidden(true)
            }

            SweepOverlay(sweep: model.sweep, succeeded: model.sweepSucceeded)
                .ignoresSafeArea()

            ScannerControls(
                zoomRange: zoomRange,
                isLive: availability.isLive,
                onPickPhoto: { isPickingPhoto = true },
                onPasteImage: pasteImage
            )
        }
        .background(Color.black)
        .photosPicker(isPresented: $isPickingPhoto, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            photoItem = nil
            Task {
                // Le sélecteur de photos doit avoir fini de se fermer avant d'ouvrir la feuille de résultat.
                guard await pause(.milliseconds(500)) else { return }
                await decode { try await ImageBarcodeDetector.detect(in: item) }
            }
        }
        .confirmationDialog(
            Text("Appairer « \(model.pairingCandidate?.name ?? "") » ?"),
            isPresented: Binding(get: { model.pairingCandidate != nil }, set: { if !$0 { model.dismissResult() } }),
            titleVisibility: .visible
        ) {
            Button("Appairer") {
                if let pairing = model.pairingCandidate {
                    do {
                        try services.macLink.pair(pairing)
                    } catch {
                        alerts.show(error)
                    }
                }
                model.dismissResult()
            }
            Button("Annuler", role: .cancel) { model.dismissResult() }
        } message: {
            Text("Ce Mac pourra recevoir vos scans quand vous activerez l’envoi depuis le scanner.")
        }
        // Pas de onDismiss : il serait appelé aussi quand la disposition change (pliage, redimensionnement)
        // et effacerait le résultat. Seule une vraie fermeture passe par le setter.
        .sheet(item: Binding(get: { model.resultEntry }, set: { if $0 == nil { model.dismissResult() } })) { entry in
            ScanResultSheet(entry: entry)
        }
        .sheet(isPresented: Binding(get: { !model.choices.isEmpty }, set: { if !$0 { model.dismissResult() } })) {
            MultipleCodesSheet(codes: model.choices) { model.choose($0) }
        }
        .overlay(alignment: .bottom) {
            if let banner = model.banner {
                AutoOpenBannerView(state: banner) {
                    model.cancelAutoOpen()
                } onFire: {
                    actions.perform(banner.action)
                    model.autoOpenCompleted()
                }
                .padding(.bottom, 110)
                .padding(.horizontal)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: model.banner?.id)
        .actionPresentations(actions)
        .task { await checkAvailability() }
        .onAppear { actions.alerts = alerts }
        .onChange(of: model.shouldScan && actions.presented == nil) { _, scanning in
            // La torche s'éteint en même temps que la session.
            if !scanning, model.isTorchOn {
                model.isTorchOn = false
                TorchController.set(false)
            }
        }
    }

    @ViewBuilder
    private var camera: some View {
        let isActive = model.shouldScan && actions.presented == nil
        switch availability {
        case .checking:
            Color.black
        case .visionKit:
            DataScannerRepresentable(
                mode: model.mode,
                batchPreset: settings.batchSymbologies,
                customSymbologies: settings.customBatchSymbologies,
                isActive: isActive,
                zoomFactor: model.zoomFactor,
                onCodes: { model.camera(didSee: $0) },
                onZoomRange: { zoomRange = $0 },
                onError: { alerts.show($0, title: String(localized: "La caméra s’est arrêtée")) },
                onUnavailable: { availability = .avFallback }
            )
            // Les symbologies ne changent pas en cours de route : on recrée le scanner.
            .id("\(model.mode.rawValue)-\(settings.batchSymbologies.rawValue)-\(settings.customBatchSymbologies.map(\.rawValue).sorted())")
        case .avFallback:
            CaptureScannerRepresentable(isActive: isActive) { model.camera(didSee: $0) }
        case .denied:
            CameraUnavailableView(reason: .denied, onPickPhoto: { isPickingPhoto = true }, onPaste: pasteImage)
        case .unavailable:
            CameraUnavailableView(reason: .noCamera, onPickPhoto: { isPickingPhoto = true }, onPaste: pasteImage)
        }
    }

    private func checkAvailability() async {
        // Sans caméra (simulateur, certains Mac), on ne demande pas une autorisation inutile.
        guard CaptureScanner.defaultDevice() != nil else {
            availability = .unavailable
            return
        }
        var status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .notDetermined {
            _ = await AVCaptureDevice.requestAccess(for: .video)
            status = AVCaptureDevice.authorizationStatus(for: .video)
        }
        switch status {
        case .authorized:
            if DataScannerViewController.isSupported && DataScannerViewController.isAvailable {
                availability = .visionKit
            } else {
                availability = .avFallback
            }
        default:
            availability = .denied
        }
    }

    private func pasteImage() {
        guard let image = UIPasteboard.general.image else {
            alerts.show(title: String(localized: "Aucune image"), detail: String(localized: "Le presse-papier ne contient pas d’image."))
            return
        }
        Task { await decode { try await ImageBarcodeDetector.detect(in: image) } }
    }

    private func decode(_ work: () async throws -> [DetectedBarcode]) async {
        do {
            model.imageDidDecode(try await work())
        } catch {
            alerts.show(error, title: String(localized: "Rien à scanner"))
        }
    }
}
