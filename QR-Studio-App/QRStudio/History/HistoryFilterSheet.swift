import QRCore
import SwiftData
import SwiftUI

/// Filtres cumulables : origine, type, symbologie, favoris, dates, dossier.
struct HistoryFilterSheet: View {
    @Binding var filter: HistoryFilter
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Folder.name) private var folders: [Folder]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Origine", selection: $filter.origin) {
                        Text("Tous").tag(CodeEntry.Origin?.none)
                        Text("Scannés").tag(CodeEntry.Origin?.some(.scanned))
                        Text("Créés").tag(CodeEntry.Origin?.some(.generated))
                    }
                    Picker("Type de contenu", selection: $filter.contentType) {
                        Text("Tous").tag(ContentType?.none)
                        ForEach(ContentType.allCases) { type in
                            Label(type.title, systemImage: type.symbolName).tag(ContentType?.some(type))
                        }
                    }
                    Picker("Format", selection: $filter.symbology) {
                        Text("Tous").tag(Symbology?.none)
                        ForEach(Symbology.allCases.filter { $0 != .unknown }) { symbology in
                            Text(symbology.displayName).tag(Symbology?.some(symbology))
                        }
                    }
                    Picker("Dossier", selection: $filter.folderID) {
                        Text("Tous").tag(UUID?.none)
                        ForEach(folders) { folder in
                            Text(folder.name).tag(UUID?.some(folder.id))
                        }
                    }
                    Toggle("Favoris seulement", isOn: $filter.favoritesOnly)
                }
                Section("Dates") {
                    OptionalDatePicker(title: "Du", date: $filter.startDate)
                    OptionalDatePicker(title: "Au", date: $filter.endDate)
                }
                if filter.activeCount > 0 {
                    Section {
                        Button("Réinitialiser les filtres", role: .destructive) {
                            let sort = filter.sort
                            filter = HistoryFilter()
                            filter.sort = sort
                        }
                    }
                }
            }
            .navigationTitle("Filtres")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
        .sheetHeight(.mediumAndLarge)
    }
}
