import QRCore
import SwiftUI

extension HistoryListView {
    var title: String {
        if baseFilter.inTrash { return String(localized: "Supprimés récemment") }
        if baseFilter.favoritesOnly { return String(localized: "Favoris") }
        if baseFilter.origin == .scanned { return String(localized: "Scannés") }
        if baseFilter.origin == .generated { return String(localized: "Créés") }
        return String(localized: "Historique")
    }

    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !model.entries.isEmpty {
                Button(editMode.isEditing ? "OK" : "Sélectionner") {
                    withAnimation {
                        editMode = editMode.isEditing ? .inactive : .active
                        selection = []
                    }
                }
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            if !baseFilter.inTrash {
                Button {
                    isShowingMap = true
                } label: {
                    Label("Carte des scans", systemImage: "map")
                }
            }
            Menu {
                Picker("Tri", selection: $extraFilter.sort) {
                    ForEach(HistoryFilter.Sort.allCases) { sort in
                        Text(sort.title).tag(sort)
                    }
                }
                Button("Filtres…", systemImage: "line.3.horizontal.decrease") { isShowingFilters = true }
                if !model.entries.isEmpty {
                    Button("Exporter…", systemImage: "square.and.arrow.up") { exportTargets = allEntriesForExport() }
                }
                if baseFilter.inTrash, !model.entries.isEmpty {
                    Divider()
                    Button("Vider la corbeille", systemImage: "trash.slash", role: .destructive) {
                        isConfirmingEmptyTrash = true
                    }
                }
            } label: {
                Label("Options", systemImage: extraFilter.activeCount > 0
                      ? "line.3.horizontal.decrease.circle.fill" : "ellipsis.circle")
            }
        }
        if editMode.isEditing {
            ToolbarItemGroup(placement: .bottomBar) {
                if baseFilter.inTrash {
                    Button("Restaurer") { restoreSelection() }
                        .disabled(selection.isEmpty)
                    Spacer()
                    Button("Supprimer", role: .destructive) { deleteSelectionPermanently() }
                        .disabled(selection.isEmpty)
                } else {
                    Button("Dossier", systemImage: "folder") { folderTargets = selectedEntriesForToolbar }
                        .disabled(selection.isEmpty)
                    Spacer()
                    Button("Exporter", systemImage: "square.and.arrow.up") { exportTargets = selectedEntriesForToolbar }
                        .disabled(selection.isEmpty)
                    Spacer()
                    Button("Supprimer", systemImage: "trash", role: .destructive) { trashSelection() }
                        .disabled(selection.isEmpty)
                }
            }
        }
    }

    @ViewBuilder
    var emptyState: some View {
        if !searchText.isEmpty || extraFilter.activeCount > 0 {
            ContentUnavailableView.search(text: searchText)
        } else if baseFilter.inTrash {
            ContentUnavailableView("La corbeille est vide", systemImage: "trash",
                                   description: Text("Les codes supprimés restent ici 30 jours."))
        } else {
            ContentUnavailableView("Aucun code pour l’instant", systemImage: "qrcode.viewfinder",
                                   description: Text("Tout ce que vous scannez ou créez apparaît ici automatiquement."))
        }
    }

    var selectedEntriesForToolbar: [CodeEntry] {
        model.entries.filter { selection.contains($0.id) }
    }

    /// Export de la vue courante : toutes les entrées qui correspondent aux filtres, pas seulement la page.
    func allEntriesForExport() -> [CodeEntry] {
        do {
            return try context.fetch(model.filter.descriptor())
        } catch {
            services.alerts.show(error)
            return []
        }
    }

    func trashSelection() {
        let entries = selectedEntriesForToolbar
        services.store.moveToTrash(entries)
        model.remove(entries)
        selection = []
        editMode = .inactive
    }

    func restoreSelection() {
        let entries = selectedEntriesForToolbar
        services.store.restore(entries)
        model.remove(entries)
        selection = []
        editMode = .inactive
    }

    func deleteSelectionPermanently() {
        let entries = selectedEntriesForToolbar
        model.remove(entries)
        services.store.deletePermanently(entries)
        selection = []
        editMode = .inactive
    }
}
