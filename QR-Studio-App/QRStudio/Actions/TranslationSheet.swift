import NaturalLanguage
import QRCore
import SwiftUI
import Translation

/// Feuille système de traduction (iOS 17.4 et plus), sans interface à construire.
struct TranslationSheet: ViewModifier {
    @Binding var isPresented: Bool
    let text: String
    /// Si fourni, la feuille propose de garder la traduction (ajoutée à la note de l'entrée).
    var onSave: ((String) -> Void)?

    func body(content: Content) -> some View {
        if #available(iOS 17.4, macOS 14.4, *) {
            content.translationPresentation(isPresented: $isPresented, text: text, replacementAction: onSave)
        } else {
            content
        }
    }
}
