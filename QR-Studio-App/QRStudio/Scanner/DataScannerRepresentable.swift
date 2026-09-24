import OSLog
import QRCore
import SwiftUI
import VisionKit

/// Pont vers DataScannerViewController. Le flux vidéo est analysé en continu :
/// aucun déclencheur, aucune photo. Le code est traité dès qu'il entre dans le champ.
struct DataScannerRepresentable: UIViewControllerRepresentable {
    let mode: ScanMode
    let batchPreset: BatchSymbologyPreset
    let customSymbologies: Set<Symbology>
    let isActive: Bool
    let zoomFactor: Double
    let onCodes: ([LiveCode]) -> Void
    let onZoomRange: (ClosedRange<Double>) -> Void
    let onError: (Error) -> Void
    /// VisionKit ne peut plus scanner (matériel, restrictions) : on bascule sur AVCaptureMetadataOutput.
    let onUnavailable: () -> Void

    /// Symbologies selon le contexte : tout en mode simple, les codes de produits en mode lot.
    /// Le texte (.text()) n'est jamais activé : il partagerait le budget de calcul et ralentirait la détection.
    private var recognizedTypes: Set<DataScannerViewController.RecognizedDataType> {
        guard mode == .batch else { return [.barcode()] }
        switch batchPreset {
        case .retail:
            return [.barcode(symbologies: [.ean13, .ean8, .upce, .code128])]
        case .custom where !customSymbologies.isEmpty:
            return [.barcode(symbologies: customSymbologies.flatMap(\.visionSymbologies))]
        default:
            return [.barcode()]
        }
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            recognizedDataTypes: recognizedTypes,
            // .fast en lot (la cadence prime), .balanced en simple ; jamais .accurate sur un flux vidéo.
            qualityLevel: mode == .batch ? .fast : .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: mode == .single,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        context.coordinator.parent = self
        if isActive, !controller.isScanning {
            do {
                try controller.startScanning()
                onZoomRange(controller.minZoomFactor...controller.maxZoomFactor)
            } catch {
                onError(error)
            }
        } else if !isActive, controller.isScanning {
            controller.stopScanning()
        }
        let clamped = min(max(zoomFactor, controller.minZoomFactor), controller.maxZoomFactor)
        if abs(controller.zoomFactor - clamped) > 0.01 {
            controller.zoomFactor = clamped
        }
    }

    static func dismantleUIViewController(_ controller: DataScannerViewController, coordinator: Coordinator) {
        controller.stopScanning()
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: DataScannerRepresentable

        init(parent: DataScannerRepresentable) {
            self.parent = parent
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            forward(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            forward(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem],
                         allItems: [RecognizedItem]) {
            forward(allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController,
                         becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            Logger.scanner.error("Scanner indisponible : \(error.localizedDescription)")
            parent.onUnavailable()
        }

        private func forward(_ items: [RecognizedItem]) {
            let codes: [LiveCode] = items.compactMap { item in
                guard case .barcode(let barcode) = item, let payload = barcode.payloadStringValue,
                      !payload.isEmpty else { return nil }
                let bounds = barcode.bounds
                return LiveCode(
                    payload: payload,
                    symbology: Symbology(vision: barcode.observation.symbology),
                    quad: Quad(topLeft: bounds.topLeft, topRight: bounds.topRight,
                               bottomRight: bounds.bottomRight, bottomLeft: bounds.bottomLeft)
                )
            }
            parent.onCodes(codes)
        }
    }
}
