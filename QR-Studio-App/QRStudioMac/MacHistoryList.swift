import QRCore
import SwiftData
import SwiftUI

/// Liste paginée (50 par page), recherche, tri et glisser vers le Finder.
struct MacHistoryList: View {
    let filter: HistoryFilter
    @Environment(\.modelContext) private var context
    @Environment(AppServices.self) private var services
    @State private var model = HistoryListModel()
    @State private var searchText = ""
    @State private var sort: HistoryFilter.Sort = .newest
    @State private var isShowingFilters = false
    @State private var extraFilter = HistoryFilter()
    @State private var exportTargets: [CodeEntry] = []

    private var effectiveFilter: HistoryFilter {
        var result = extraFilter
        result.searchText = searchText
        result.sort = sort
        result.inTrash = filter.inTrash
        result.favoritesOnly = result.favoritesOnly || filter.favoritesOnly
        result.origin = result.origin ?? filter.origin
        result.folderID = result.folderID ?? filter.folderID
        return result
    }

    var body: some View {
        @Bindable var services = services
        List(selection: $services.selectedEntryID) {
            ForEach(model.sections) { section in
                Section(section.id == .distantPast ? "" : Self.dayTitle(section.id)) {
                    ForEach(section.entries) { entry in
                        HistoryRow(entry: entry)
                            .frame(minHeight: 52)
                            .tag(entry.id)
                            .draggable(DraggableCode(entry: entry))
                            .contextMenu { contextMenu(for: entry) }
                            .onAppear { model.loadMoreIfNeeded(current: entry, in: context) }
                    }
                }
            }
        }
        .listStyle(.inset)
        // La hauteur de rangée par défaut de macOS coupe la vignette et la ligne de contenu.
        .environment(\.defaultMinListRowHeight, 60)
        .overlay {
            if model.entries.isEmpty {
                if searchText.isEmpty {
                    ContentUnavailableView(filter.inTrash ? "La corbeille est vide" : "Aucun code pour l’instant",
                                           systemImage: filter.inTrash ? "trash" : "qrcode.viewfinder")
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
        .modifier(SearchFocus(text: $searchText, isFocused: $services.isSearchFocused))
        .toolbar {
            ToolbarItem {
                Menu {
                    Picker("Tri", selection: $sort) {
                        ForEach(HistoryFilter.Sort.allCases) { Text($0.title).tag($0) }
                    }
                    Button("Filtres…") { isShowingFilters = true }
                    Button("Exporter la liste…") { exportTargets = allEntries() }
                } label: {
                    Label("Options", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        // ⌘C sur la liste : le contenu du code sélectionné.
        .onCopyCommand {
            guard let id = services.selectedEntryID, let entry = model.entries.first(where: { $0.id == id }) else { return [] }
            return [NSItemProvider(object: entry.rawValue as NSString)]
        }
        .onDeleteCommand {
            guard let id = services.selectedEntryID, let entry = model.entries.first(where: { $0.id == id }) else { return }
            remove(entry)
        }
        .sheet(isPresented: $isShowingFilters) {
            HistoryFilterSheet(filter: $extraFilter)
        }
        .sheet(isPresented: Binding(get: { !exportTargets.isEmpty }, set: { if !$0 { exportTargets = [] } })) {
            MacListExportSheet(entries: exportTargets)
        }
        .task(id: effectiveFilter) {
            model.filter = effectiveFilter
            model.reset(in: context)
        }
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in
            model.reload(in: context)
        }
    }

    @ViewBuilder
    private func contextMenu(for entry: CodeEntry) -> some View {
        Button("Copier le contenu") { Pasteboard.copy(entry.rawValue) }
        Button(entry.isFavorite ? "Retirer des favoris" : "Ajouter aux favoris") {
            entry.isFavorite.toggle()
            services.store.updated([entry])
        }
        Button("Dupliquer") { _ = services.store.duplicate(entry) }
        Divider()
        if filter.inTrash {
            Button("Restaurer") {
                services.store.restore([entry])
                model.remove([entry])
            }
            Button("Supprimer définitivement", role: .destructive) {
                model.remove([entry])
                services.store.deletePermanently([entry])
            }
        } else {
            Button("Supprimer", role: .destructive) { remove(entry) }
        }
    }

    private func remove(_ entry: CodeEntry) {
        if filter.inTrash {
            model.remove([entry])
            services.store.deletePermanently([entry])
        } else {
            services.store.moveToTrash([entry])
            model.remove([entry])
        }
        if services.selectedEntryID == entry.id { services.selectedEntryID = nil }
    }

    private func allEntries() -> [CodeEntry] {
        do {
            return try context.fetch(model.filter.descriptor())
        } catch {
            services.alerts.show(error)
            return []
        }
    }

    static func dayTitle(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return String(localized: "Aujourd’hui") }
        if calendar.isDateInYesterday(day) { return String(localized: "Hier") }
        return day.formatted(date: .complete, time: .omitted)
    }
}
