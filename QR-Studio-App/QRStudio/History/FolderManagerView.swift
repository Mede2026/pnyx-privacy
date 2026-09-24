import QRCore
import SwiftData
import SwiftUI

/// Dossiers : nom, icône SF Symbols et couleur. Un code appartient à zéro ou un dossier.
struct FolderManagerView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AlertCenter.self) private var alerts
    @Query(sort: \Folder.name) private var folders: [Folder]
    @State private var editing: Folder?
    @State private var isCreating = false

    var body: some View {
        List {
            ForEach(folders) { folder in
                Button {
                    editing = folder
                } label: {
                    HStack {
                        Image(systemName: folder.symbolName)
                            .foregroundStyle(RGBAColor(hex: folder.colorHex)?.color ?? .accentColor)
                            .frame(width: 28)
                        Text(folder.name)
                        Spacer()
                        Text("\(folder.activeCount)")
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
                .foregroundStyle(.primary)
            }
            .onDelete { offsets in
                for index in offsets { context.delete(folders[index]) }
                save()
            }
        }
        .overlay {
            if folders.isEmpty {
                ContentUnavailableView("Aucun dossier", systemImage: "folder",
                                       description: Text("Les dossiers aident à classer vos codes : cartes de fidélité, Wi-Fi, produits…"))
            }
        }
        .navigationTitle("Dossiers")
        .alertHost()
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("OK") { dismiss() }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Nouveau dossier", systemImage: "folder.badge.plus") { isCreating = true }
            }
        }
        .sheet(item: $editing) { folder in
            FolderEditor(folder: folder)
        }
        .sheet(isPresented: $isCreating) {
            FolderEditor(folder: nil)
        }
    }

    private func save() {
        do {
            try context.save()
        } catch {
            alerts.show(error)
        }
    }
}

extension RGBAColor {
    init(_ resolved: Color.Resolved) {
        self.init(red: Double(resolved.red), green: Double(resolved.green), blue: Double(resolved.blue),
                  alpha: Double(resolved.opacity))
    }
}
