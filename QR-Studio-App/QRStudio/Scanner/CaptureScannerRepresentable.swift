import AVFoundation
import QRCore
import SwiftUI
import UIKit

/// Repli AVCaptureMetadataOutput quand le matériel ne prend pas en charge VisionKit.
struct CaptureScannerRepresentable: UIViewRepresentable {
    let isActive: Bool
    let onCodes: ([LiveCode]) -> Void

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        let scanner = context.coordinator.scanner
        view.previewLayer.session = scanner.session
        view.previewLayer.videoGravity = .resizeAspectFill
        scanner.onObjects = { [weak view] objects in
            guard let view else { return }
            let codes: [LiveCode] = objects.compactMap { object in
                guard let payload = object.stringValue, !payload.isEmpty,
                      let transformed = view.previewLayer.transformedMetadataObject(for: object)
                        as? AVMetadataMachineReadableCodeObject,
                      transformed.corners.count == 4 else { return nil }
                let c = transformed.corners
                return LiveCode(payload: payload, symbology: Symbology(metadataType: object.type),
                                quad: Quad(topLeft: c[0], topRight: c[1], bottomRight: c[2], bottomLeft: c[3]))
            }
            onCodes(codes)
        }
        scanner.configure()
        return view
    }

    func updateUIView(_ view: PreviewView, context: Context) {
        if isActive {
            context.coordinator.scanner.start()
        } else {
            context.coordinator.scanner.stop()
        }
    }

    static func dismantleUIView(_ view: PreviewView, coordinator: Coordinator) {
        coordinator.scanner.stop()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator {
        let scanner = CaptureScanner()
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        // La classe du calque est fixée par layerClass : la conversion ne peut pas échouer.
        var previewLayer: AVCaptureVideoPreviewLayer {
            guard let layer = layer as? AVCaptureVideoPreviewLayer else {
                preconditionFailure("layerClass doit être AVCaptureVideoPreviewLayer")
            }
            return layer
        }
    }
}
