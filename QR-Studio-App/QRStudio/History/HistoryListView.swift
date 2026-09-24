import QRCore
import SwiftData
import SwiftUI

/// Liste paginée de l'historique : sections par jour, recherche, filtres, gestes et sélection multiple.
struct HistoryListView: View {
    let baseFilter: HistoryFilter
    @Environment(\.modelContext) var context
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(AppServices.self) var services
    @Environment(AppRouter.self) var router
    @State var model = HistoryListModel()
    @State var searchText = ""
    @State var extraFilter = HistoryFilter()
    @State var isShowingFilters = false
    @State var isShowingMap = false
    @State var editMode: EditMode = .inactive
    @State var selection = Set<UUID>()
    @State var isConfirmingEmptyTrash = false
    @State var styleTarget: CodeEntry?
    @State var folderTargets: [CodeEntry] = []
    @State var exportTargets: [CodeEntry] = []

    init(filter: HistoryFilter) {
        baseFilter = filter
    }

    var effectiveFilter: HistoryFilter {
        var filter = extraFilter
        filter.searchText = searchText
        filter.inTrash = baseFilter.inTrash
        filter.favoritesOnly = filter.favoritesOnly || baseFilter.favoritesOnly
        filter.origin = filter.origin ?? baseFilter.origin
        filter.folderID = filter.folderID ?? baseFilter.folderID
        return filter
    }

    var body: some View {
        list
            .overlay {
                if model.entries.isEmpty {
                    emptyState
                }
            }
            .searchable(text: $searchText, prompt: Text("Chercher dans les codes, notes, libellés"))
            .onSubmit(of: .search) { Task { await smartSearch() } }
            .navigationTitle(title)
            .toolbar { toolbar }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $isShowingFilters) {
                HistoryFilterSheet(filter: $extraFilter)
            }
            .sheet(item: $styleTarget) { entry in
                NavigationStack { EntryStyleEditor(entry: entry) }
            }
            .sheet(isPresented: Binding(get: { !folderTargets.isEmpty }, set: { if !$0 { folderTargets = [] } })) {
                FolderPickerSheet { folder in
                    for entry in folderTargets { entry.folder = folder }
                    services.store.updated(folderTargets)
                    finishSelection()
                }
            }
            .sheet(isPresented: Binding(get: { !exportTargets.isEmpty }, set: { if !$0 { exportTargets = [] } })) {
                ExportEntriesSheet(entries: exportTargets, title: title)
            }
            .navigationDestination(isPresented: $isShowingMap) { ScanMapView() }
            .confirmationDialog("Vider la corbeille ?", isPresented: $isConfirmingEmptyTrash, titleVisibility: .visible) {
                Button("Supprimer définitivement", role: .destructive) {
                    services.store.deletePermanently(model.entries)
                    model.reset(in: context)
                }
            } message: {
                Text("Ces codes seront supprimés sur tous vos appareils. Cette action est irréversible.")
            }
            .onChange(of: router.pendingSearch, initial: true) { _, search in
                guard let search else { return }
                searchText = search
                router.pendingSearch = nil
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
    var list: some View {
        if editMode.isEditing || sizeClass == .compact {
            List(selection: $selection) { rows }
        } else {
            @Bindable var router = router
            List(selection: $router.selectedEntryID) { rows }
        }
    }

    var rows: some View {
        ForEach(model.sections) { section in
            Section {
                ForEach(section.entries) { entry in
                    row(for: entry)
                        .tag(entry.id)
                        .onAppear { model.loadMoreIfNeeded(current: entry, in: context) }
                }
            } header: {
                if section.id != .distantPast {
                    Text(Self.dayTitle(section.id))
                }
            }
        }
    }

    @ViewBuilder
    func row(for entry: CodeEntry) -> some View {
        let content = HistoryRow(entry: entry)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                if baseFilter.inTrash {
                    Button("Supprimer", systemImage: "trash", role: .destructive) { deletePermanently([entry]) }
                } else {
                    Button("Supprimer", systemImage: "trash", role: .destructive) { moveToTrash([entry]) }
                }
            }
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                if baseFilter.inTrash {
                    Button("Restaurer", systemImage: "arrow.uturn.backward") { restore([entry]) }
                        .tint(.green)
                } else {
                    Button(entry.isFavorite ? "Retirer" : "Favori", systemImage: entry.isFavorite ? "star.slash" : "star") {
                        entry.isFavorite.toggle()
                        services.store.updated([entry])
                    }
                    .tint(.yellow)
                }
            }
            .contextMenu { contextMenu(for: entry) }
        if sizeClass == .compact && !editMode.isEditing {
            NavigationLink(value: entry.id) { content }
        } else {
            content
        }
    }

    @ViewBuilder
    func contextMenu(for entry: CodeEntry) -> some View {
        Button("Copier", systemImage: "doc.on.doc") { Pasteboard.copy(entry.rawValue) }
        ShareLink(item: DraggableCode(entry: entry), preview: SharePreview(entry.displayTitle)) {
            Label("Partager l’image", systemImage: "square.and.arrow.up")
        }
        ShareLink(item: entry.rawValue) { Label("Partager le contenu", systemImage: "text.bubble") }
        Button("Dupliquer", systemImage: "plus.square.on.square") { _ = services.store.duplicate(entry) }
        if entry.renderRequest.symbology.supportsFullStyling {
            Button("Modifier le style", systemImage: "paintbrush") { styleTarget = entry }
        }
        Button("Déplacer dans un dossier", systemImage: "folder") { folderTargets = [entry] }
        Divider()
        Button("Supprimer", systemImage: "trash", role: .destructive) { moveToTrash([entry]) }
    }

    /// Une phrase (plusieurs mots) validée au clavier passe par le modèle embarqué s'il est disponible ;
    /// sinon la recherche par mots-clés reste active.
    func smartSearch() async {
        let sentence = searchText.trimmingCharacters(in: .whitespaces)
        guard sentence.split(separator: " ").count >= 3,
              let filter = await OnDeviceIntelligence.searchFilter(for: sentence) else { return }
        extraFilter.contentType = filter.contentType
        extraFilter.startDate = filter.startDate
        extraFilter.endDate = filter.endDate
        extraFilter.favoritesOnly = filter.favoritesOnly
        searchText = filter.searchText
    }

    func moveToTrash(_ entries: [CodeEntry]) {
        services.store.moveToTrash(entries)
        model.remove(entries)
    }

    func restore(_ entries: [CodeEntry]) {
        services.store.restore(entries)
        model.remove(entries)
    }

    func deletePermanently(_ entries: [CodeEntry]) {
        model.remove(entries)
        services.store.deletePermanently(entries)
    }

    var selectedEntries: [CodeEntry] {
        model.entries.filter { selection.contains($0.id) }
    }

    func finishSelection() {
        selection = []
        editMode = .inactive
    }

    static func dayTitle(_ day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return String(localized: "Aujourd’hui") }
        if calendar.isDateInYesterday(day) { return String(localized: "Hier") }
        return day.formatted(date: .complete, time: .omitted)
    }
}
