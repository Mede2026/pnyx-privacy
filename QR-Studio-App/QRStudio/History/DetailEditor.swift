import QRCore
import SwiftUI

/// Libellé, note, dossier, code principal : modifiables depuis le détail.
struct DetailEditor: View {
    @Bindable var entry: CodeEntry
    let onChooseFolder: () -> Void
    @Environment(AppServices.self) private var services

    var body: some View {
        CardSection {
            LabelField(entry: entry)
            Divider()
            TextField("Ajouter une note", text: $entry.note, axis: .vertical)
                .lineLimit(1...6)
                .onSubmit { services.store.updated([entry]) }
            Divider()
            Button(action: onChooseFolder) {
                LabeledContent {
                    Text(entry.folder?.name ?? String(localized: "Aucun"))
                } label: {
                    Label("Dossier", systemImage: "folder")
                }
            }
            .foregroundStyle(.primary)
            Divider()
            Toggle(isOn: Binding(get: { entry.isPrimary }, set: { _ in services.store.setPrimary(entry) })) {
                Label("Code principal sur l’Apple Watch", systemImage: "applewatch")
            }
        }
        .onDisappear { services.store.updated([entry]) }
    }
}
