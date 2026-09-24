import Foundation
import Observation
import QRCore

/// Liste du mode lot : les doublons sont regroupés avec une quantité.
@MainActor
@Observable
final class BatchSession {
    struct Item: Identifiable {
        var id: UUID { entry.id }
        let entry: CodeEntry
    }

    private(set) var items: [Item] = []

    var count: Int { items.reduce(0) { $0 + max(1, $1.entry.quantity) } }
    var isEmpty: Bool { items.isEmpty }
    var entries: [CodeEntry] { items.map(\.entry) }

    func contains(_ payload: String) -> Bool {
        items.contains { $0.entry.rawValue == payload }
    }

    func append(_ entry: CodeEntry) {
        items.insert(Item(entry: entry), at: 0)
    }

    func increment(_ payload: String, store: EntryStore?) {
        guard let index = items.firstIndex(where: { $0.entry.rawValue == payload }) else { return }
        let entry = items[index].entry
        entry.quantity += 1
        // Le code revient en tête de liste pour montrer ce qui vient d'être compté.
        items.remove(at: index)
        items.insert(Item(entry: entry), at: 0)
        store?.updated([entry])
    }

    func remove(_ entry: CodeEntry) {
        items.removeAll { $0.entry.id == entry.id }
    }

    /// Vide la liste du lot ; les entrées restent dans l'historique.
    func clear() {
        items.removeAll()
    }
}
