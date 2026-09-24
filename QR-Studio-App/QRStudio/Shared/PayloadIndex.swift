import Foundation
import OSLog
import QRCore
import SwiftData

/// Index en mémoire contenu → entrées, pour répondre à Visual Intelligence en quelques millisecondes :
/// une recherche par hachage, jamais un parcours de la base. Construit une fois au lancement,
/// mis à jour à chaque écriture, jamais à la lecture.
@MainActor
final class PayloadIndex {
    private var ids: [String: [UUID]] = [:]

    func rebuild(from context: ModelContext) {
        do {
            let entries = try context.fetch(FetchDescriptor<CodeEntry>(predicate: #Predicate { $0.deletedAt == nil }))
            ids = Dictionary(grouping: entries, by: \.rawValue).mapValues { $0.map(\.id) }
        } catch {
            Logger.persistence.error("Index des contenus non construit : \(error.localizedDescription)")
        }
    }

    func update(_ entries: [CodeEntry], kind: EntryStore.ChangeKind) {
        for entry in entries {
            ids[entry.rawValue, default: []].removeAll { $0 == entry.id }
            if kind == .upserted, entry.deletedAt == nil {
                ids[entry.rawValue, default: []].insert(entry.id, at: 0)
            }
            if ids[entry.rawValue]?.isEmpty == true { ids[entry.rawValue] = nil }
        }
    }

    /// Identifiants des entrées correspondant aux contenus lus, 5 au plus.
    func matches(for payloads: [String], limit: Int = 5) -> [UUID] {
        var result: [UUID] = []
        for payload in payloads {
            for id in ids[payload] ?? [] where !result.contains(id) {
                result.append(id)
                if result.count == limit { return result }
            }
        }
        return result
    }
}
