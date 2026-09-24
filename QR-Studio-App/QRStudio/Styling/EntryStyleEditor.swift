import QRCore
import SwiftData
import SwiftUI

/// Édition du style d'une entrée existante de l'historique.
struct EntryStyleEditor: View {
    let entry: CodeEntry
    @Environment(AppServices.self) private var services
    @State private var style = StyleConfig()

    var body: some View {
        StyleEditorView(style: $style, payload: entry.rawValue) { newStyle in
            if let existing = entry.style {
                existing.apply(newStyle)
            } else {
                entry.style = CodeStyle(config: newStyle)
            }
            services.store.updated([entry])
        }
        .onAppear { style = entry.style?.config ?? StyleConfig() }
    }
}
