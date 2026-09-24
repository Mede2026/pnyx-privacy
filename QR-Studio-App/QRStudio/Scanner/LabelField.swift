import QRCore
import SwiftData
import SwiftUI

/// Champ libellé, prérempli par une suggestion quand le modèle embarqué est disponible.
struct LabelField: View {
    @Bindable var entry: CodeEntry
    @Environment(AppServices.self) private var services

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            TextField("Libellé", text: $entry.label)
                .font(.headline)
                .onSubmit { services.store.updated([entry]) }
            LabelSuggestionRow(entry: entry)
        }
    }
}
