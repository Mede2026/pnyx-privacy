import QRCore
import SwiftUI

/// Aperçu d'un code, rendu hors du fil principal. Quand la demande change, la tâche précédente
/// est annulée (.task(id:)) : les rendus ne s'empilent pas pendant la frappe.
struct CodePreview: View {
    let request: RenderRequest?
    var pixelWidth = 900
    /// Anti-rebond avant le rendu (300 ms pendant la saisie, 0 pour un affichage fixe).
    var debounce: Duration = .zero
    var onRendered: ((PlatformImage) -> Void)?
    @State private var image: PlatformImage?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            if let image {
                Image(platformImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel(Text("Aperçu du code"))
            } else if let errorMessage {
                ContentUnavailableView {
                    Label("Impossible de dessiner ce code", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(errorMessage)
                }
            } else if request == nil {
                Image(systemName: "qrcode")
                    .font(.system(size: 80, weight: .ultraLight))
                    .foregroundStyle(.quaternary)
                    .accessibilityHidden(true)
            } else {
                ProgressView()
            }
        }
        .task(id: request) {
            guard let request else {
                image = nil
                errorMessage = nil
                return
            }
            if debounce > .zero {
                guard await pause(debounce) else { return }
            }
            do {
                let drawing = try await CodeRenderer.shared.drawing(for: request)
                let width = pixelWidth
                let data = try await Task.detached(priority: .userInitiated) {
                    try drawing.pngData(width: width)
                }.value
                guard !Task.isCancelled, let rendered = PlatformImage(data: data) else { return }
                image = rendered
                errorMessage = nil
                onRendered?(rendered)
            } catch is CancellationError {
                return
            } catch {
                image = nil
                errorMessage = error.localizedDescription
            }
        }
    }
}
