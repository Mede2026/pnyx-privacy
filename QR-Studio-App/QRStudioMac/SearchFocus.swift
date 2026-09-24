import AppKit
import QRCore
import SwiftData
import SwiftUI

/// Recherche dans la barre d'outils ; ⌘F y place le curseur.
struct SearchFocus: ViewModifier {
    @Binding var text: String
    @Binding var isFocused: Bool
    @FocusState private var focus: Bool

    func body(content: Content) -> some View {
        if #available(macOS 15.0, *) {
            content
                .searchable(text: $text, prompt: Text("Chercher dans les codes, notes, libellés"))
                .searchFocused($focus)
                .onChange(of: isFocused) { _, requested in
                    if requested {
                        focus = true
                        isFocused = false
                    }
                }
        } else {
            // macOS 14 : pas de searchFocused ; on donne le focus au champ de la barre d'outils.
            content
                .searchable(text: $text, prompt: Text("Chercher dans les codes, notes, libellés"))
                .onChange(of: isFocused) { _, requested in
                    guard requested else { return }
                    isFocused = false
                    guard let window = NSApp.keyWindow,
                          let item = window.toolbar?.items.lazy.compactMap({ $0 as? NSSearchToolbarItem }).first else { return }
                    window.makeFirstResponder(item.searchField)
                }
        }
    }
}
