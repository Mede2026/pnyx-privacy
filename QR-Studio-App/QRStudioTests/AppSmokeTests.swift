import QRCore
import SwiftData
import Testing
@testable import QRStudio

@MainActor
@Suite("Historique")
final class AppSmokeTests {
    /// Les conteneurs restent en vie pendant tout le test : un ModelContext ne retient pas son conteneur.
    private var containers: [ModelContainer] = []

    private func makeStore() throws -> EntryStore {
        let container = try AppModelContainer.make(cloudSync: false, inMemory: true)
        containers.append(container)
        return EntryStore(context: container.mainContext, alerts: AlertCenter())
    }

    @Test func scanIsRecordedWithParsedType() throws {
        let store = try makeStore()
        let entry = store.recordScan(payload: "https://marque.com/01/09506000134376", symbology: .qr)
        #expect(entry.contentKind == .product)
        #expect(entry.productCode == "09506000134376")
        #expect(store.fetchEntry(id: entry.id) != nil)
    }

    @Test func trashHidesEntriesFromTheList() throws {
        let store = try makeStore()
        let kept = store.recordScan(payload: "Bonjour", symbology: .qr)
        let trashed = store.recordScan(payload: "Au revoir", symbology: .qr)
        store.moveToTrash([trashed])
        let active = try store.context.fetch(HistoryFilter().descriptor())
        #expect(active.map(\.id) == [kept.id])
        var trash = HistoryFilter()
        trash.inTrash = true
        #expect(try store.context.fetch(trash.descriptor()).map(\.id) == [trashed.id])
    }

    @Test func filtersCombine() throws {
        let store = try makeStore()
        let favorite = store.recordScan(payload: "tel:+15145550123", symbology: .qr)
        favorite.isFavorite = true
        store.recordScan(payload: "tel:+15145550999", symbology: .qr)
        store.recordGenerated(payload: "Texte", symbology: .qr, contentType: .text, style: nil, label: "Note chalet")
        var filter = HistoryFilter()
        filter.contentType = .phone
        filter.favoritesOnly = true
        #expect(try store.context.fetch(filter.descriptor()).map(\.id) == [favorite.id])
        var search = HistoryFilter()
        search.searchText = "chalet"
        #expect(try store.context.fetch(search.descriptor()).count == 1)
    }

    @Test func pagination() throws {
        let store = try makeStore()
        for index in 0..<120 { store.recordScan(payload: "code \(index)", symbology: .qr) }
        let model = HistoryListModel()
        model.reset(in: store.context)
        #expect(model.entries.count == HistoryListModel.pageSize)
        #expect(model.hasMore)
        if let last = model.entries.last { model.loadMoreIfNeeded(current: last, in: store.context) }
        #expect(model.entries.count == 100)
    }

    @Test func backupRoundTrip() throws {
        let store = try makeStore()
        let folder = Folder(name: "Cartes")
        store.context.insert(folder)
        let entry = store.recordGenerated(payload: "https://exemple.com", symbology: .qr, contentType: .url,
                                          style: StylePresets.all[2].config, label: "Site")
        entry.folder = folder
        store.updated([entry])
        let data = try BackupCodec.export(from: store.context)

        let other = try makeStore()
        let summary = try BackupCodec.restore(try BackupCodec.decode(data), into: other.context, mode: .merge)
        #expect(summary.added == 1)
        let restored = try #require(other.fetchEntry(id: entry.id))
        #expect(restored.folder?.name == "Cartes")
        #expect(restored.style?.config == entry.style?.config)
        let again = try BackupCodec.restore(try BackupCodec.decode(data), into: other.context, mode: .merge)
        #expect(again.skipped == 1)
    }
}
