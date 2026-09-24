import SwiftUI

/// Conteneur obligatoire dès que plusieurs éléments en verre se côtoient :
/// le verre ne doit pas échantillonner du verre. Ne jamais en imbriquer deux.
struct GlassGroup<Content: View>: View {
    var spacing: CGFloat = 12
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}
