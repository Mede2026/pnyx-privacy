import AVFoundation
import AppKit
import QRCore
import SwiftUI

/// Aperçu vidéo AppKit.
struct CameraPreview: NSViewRepresentable {
    let scanner: CaptureScanner

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        let layer = AVCaptureVideoPreviewLayer(session: scanner.session)
        layer.videoGravity = .resizeAspectFill
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        view.layer = layer
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {}
}
