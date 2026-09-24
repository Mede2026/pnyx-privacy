import QRCore
import SwiftUI

/// Commandes flottantes en verre, posées sur l'aperçu caméra. Rien n'est caché dans un menu.
struct ScannerControls: View {
    @Environment(ScannerModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    let zoomRange: ClosedRange<Double>
    let isLive: Bool
    let onPickPhoto: () -> Void
    let onPasteImage: () -> Void
    @State private var clipboardHasImage = false

    var body: some View {
        VStack(spacing: 12) {
            VStack(spacing: 10) {
                ModeSwitcher()
                MacConnectionChip()
            }
            .padding(.top, 8)
            Spacer()
            if model.stacksResults {
                BatchPanel()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if clipboardHasImage, !model.stacksResults {
                Button(action: onPasteImage) {
                    Label("Analyser l’image du presse-papier", systemImage: "doc.on.clipboard")
                        .font(.footnote.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                }
                .glassButtonStyle()
            }
            bottomBar
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .animation(.snappy, value: model.mode)
        .onAppear { clipboardHasImage = UIPasteboard.general.hasImages }
        // Une image copiée dans une autre app : on revérifie au retour au premier plan.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { clipboardHasImage = UIPasteboard.general.hasImages }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIPasteboard.changedNotification)) { _ in
            clipboardHasImage = UIPasteboard.general.hasImages
        }
    }

    private var bottomBar: some View {
        GlassGroup(spacing: 14) {
            HStack(spacing: 14) {
                if isLive && TorchController.isAvailable {
                    TorchControl()
                }
                CircleControl(systemImage: "photo.on.rectangle", label: "Scanner une photo", action: onPickPhoto)
                if isLive && zoomRange.upperBound >= 2 && !model.isTorchOn {
                    ZoomSelector(zoomRange: zoomRange)
                }
                Spacer(minLength: 0)
                LastScanButton()
            }
        }
    }
}
