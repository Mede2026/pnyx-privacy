import Foundation
import SwiftData
import Testing
@testable import QRCore

@MainActor
@Suite("Prédicat de l'historique exécuté par SwiftData")
struct HistoryPredicateTests {
    private func criteria() -> HistoryPredicate.Criteria {
        HistoryPredicate.Criteria(origins: CodeEntry.Origin.allCases.map(\.rawValue),
                                  contentTypes: ContentType.allCases.map(\.rawValue),
                                  symbologies: Symbology.allCases.map(\.rawValue))
    }

    private func fetch(_ c: HistoryPredicate.Criteria, in context: ModelContext) throws -> [String] {
        try context.fetch(FetchDescriptor(predicate: HistoryPredicate.make(c), sortBy: [SortDescriptor(\.rawValue)])).map(\.rawValue)
    }

    @Test func combinedFilters() throws {
        let container = try AppModelContainer.make(cloudSync: false, inMemory: true)
        let context = container.mainContext
        let folder = Folder(name: "Chalet")
        context.insert(folder)
        let a = CodeEntry(rawValue: "https://chalet.ca", symbology: .qr, contentType: .url, origin: .scanned)
        a.folder = folder
        a.isFavorite = true
        let b = CodeEntry(rawValue: "4006381333931", symbology: .ean13, contentType: .product, origin: .scanned)
        b.note = "Café du chalet"
        let c = CodeEntry(rawValue: "Bonjour", symbology: .qr, contentType: .text, origin: .generated)
        c.deletedAt = .now
        let d = CodeEntry(rawValue: "tel:+1514", symbology: .qr, contentType: .phone, origin: .generated,
                          createdAt: Date(timeIntervalSince1970: 0))
        for entry in [a, b, c, d] { context.insert(entry) }
        try context.save()

        #expect(try fetch(criteria(), in: context) == ["4006381333931", "https://chalet.ca", "tel:+1514"])

        var trash = criteria()
        trash.inTrash = true
        #expect(try fetch(trash, in: context) == ["Bonjour"])

        var search = criteria()
        search.text = "CHALET"
        #expect(try fetch(search, in: context) == ["4006381333931", "https://chalet.ca"])

        var inFolder = criteria()
        inFolder.folderID = folder.id
        #expect(try fetch(inFolder, in: context) == ["https://chalet.ca"])

        var favorites = criteria()
        favorites.favoritesOnly = true
        #expect(try fetch(favorites, in: context) == ["https://chalet.ca"])

        var generated = criteria()
        generated.origins = ["generated"]
        #expect(try fetch(generated, in: context) == ["tel:+1514"])

        var products = criteria()
        products.contentTypes = ["product"]
        products.symbologies = ["ean13"]
        #expect(try fetch(products, in: context) == ["4006381333931"])

        var recent = criteria()
        recent.from = Date(timeIntervalSince1970: 1000)
        #expect(try fetch(recent, in: context) == ["4006381333931", "https://chalet.ca"])
    }
}
