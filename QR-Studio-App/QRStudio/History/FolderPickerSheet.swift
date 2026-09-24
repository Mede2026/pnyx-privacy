import QRCore
import SwiftData
import SwiftUI

/// Choix d'un dossier (ou aucun) pour ranger un ou plusieurs codes.
struct FolderPickerSheet: View {
    let onPick: (Folder?) -> Void
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Folder.name) private var folders: [Folder]
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            List {
                Button {
                    onPick(nil)
                    dismiss()
                } label: {
                    Label("Aucun dossier", systemImage: "tray")
                }
                ForEach(folders) { folder in
                    Button {
                        onPick(folder)
                        dismiss()
                    } label: {
                        Label {
                            Text(folder.name)
                        } icon: {
                            Image(systemName: folder.symbolName)
                                .foregroundStyle(RGBAColor(hex: folder.colorHex)?.color ?? .accentColor)
                        }
                    }
                }
                Button {
                    isCreating = true
                } label: {
                    Label("Nouveau dossier…", systemImage: "folder.badge.plus")
                }
            }
            .foregroundStyle(.primary)
            .navigationTitle("Déplacer vers")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
            }
            .sheet(isPresented: $isCreating) {
                FolderEditor(folder: nil) { folder in
                    onPick(folder)
                    dismiss()
                }
            }
        }
        .sheetHeight(.mediumAndLarge)
        .alertHost()
    }
}
