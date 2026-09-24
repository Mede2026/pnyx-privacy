import QRCore
import SwiftUI

/// Aperçu figé en haut du formulaire, avec l'indicateur de lisibilité.
struct PinnedPreview: View {
    let request: RenderRequest?
    let readability: Readability?
    let colorCheck: ColorCheck

    var body: some View {
        VStack(spacing: 8) {
            CodePreview(request: request, pixelWidth: 600, debounce: .milliseconds(300))
                .frame(height: 170)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            ReadabilityIndicator(readability: request == nil ? nil : readability, colorCheck: colorCheck)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}
