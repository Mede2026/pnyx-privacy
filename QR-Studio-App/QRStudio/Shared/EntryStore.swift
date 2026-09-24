import CoreLocation
import Foundation
import OSLog
import QRCore
import SwiftData

/// Point d'écriture unique de l'historique : scans, créations, corbeille.
/// Toute écriture passe ici pour que l'indexation (Spotlight, index des payloads) suive.
@MainActor
final class EntryStore {
    let context: ModelContext
    private let alerts: AlertCenter
    /// Appelé après chaque écriture réussie, avec les entrées touchées.
    var onChange: [([CodeEntry], ChangeKind) -> Void] = []

    enum ChangeKind {
        case upserted
        case removed
    }

    init(context: ModelContext, alerts: AlertCenter) {
        self.context = context
        self.alerts = alerts
    }

    /// Enregistre un code scanné, immédiatement, avant toute action de l'utilisateur.
    @discardableResult
    func recordScan(payload: String, symbology: Symbology, location: CLLocation? = nil) -> CodeEntry {
        let parsed = ScannedContentParser.parse(payload, symbology: symbology)
        let entry = CodeEntry(rawValue: payload, symbology: symbology, contentType: parsed.contentType, origin: .scanned)
        if case .product(let product) = parsed { entry.productCode = product.gtin }
        if let location {
            entry.latitude = location.coordinate.latitude
            entry.longitude = location.coordinate.longitude
        }
        context.insert(entry)
        save([entry], .upserted)
        return entry
    }

    @discardableResult
    func recordGenerated(payload: String, symbology: Symbology, contentType: ContentType,
                         style: StyleConfig?, label: String = "") -> CodeEntry {
        let entry = CodeEntry(rawValue: payload, symbology: symbology, contentType: contentType, origin: .generated)
        entry.label = label
        if contentType == .product { entry.productCode = GTIN.normalized(payload) }
        if let style { entry.style = CodeStyle(config: style) }
        context.insert(entry)
        save([entry], .upserted)
        return entry
    }

    func updated(_ entries: [CodeEntry]) {
        save(entries, .upserted)
    }

    func duplicate(_ entry: CodeEntry) -> CodeEntry {
        let copy = CodeEntry(rawValue: entry.rawValue, symbology: entry.symbologyKind,
                             contentType: entry.contentKind, origin: entry.originKind)
        copy.label = entry.label
        copy.note = entry.note
        copy.productCode = entry.productCode
        copy.folder = entry.folder
        if let style = entry.style { copy.style = CodeStyle(config: style.config) }
        context.insert(copy)
        save([copy], .upserted)
        return copy
    }

    /// Corbeille de 30 jours : l'entrée est masquée, pas supprimée.
    func moveToTrash(_ entries: [CodeEntry]) {
        for entry in entries {
            entry.deletedAt = .now
            entry.isPrimary = false
        }
        save(entries, .removed)
    }

    func restore(_ entries: [CodeEntry]) {
        for entry in entries { entry.deletedAt = nil }
        save(entries, .upserted)
    }

    func deletePermanently(_ entries: [CodeEntry]) {
        let snapshot = entries
        for entry in entries { context.delete(entry) }
        save(snapshot, .removed)
    }

    /// Un seul code principal (pour la complication de la montre).
    func setPrimary(_ entry: CodeEntry) {
        let wasPrimary = entry.isPrimary
        do {
            let current = try context.fetch(FetchDescriptor<CodeEntry>(predicate: #Predicate { $0.isPrimary }))
            for other in current { other.isPrimary = false }
            entry.isPrimary = !wasPrimary
            save(current + [entry], .upserted)
        } catch {
            alerts.show(error)
        }
    }

    func fetchEntry(id: UUID) -> CodeEntry? {
        var descriptor = FetchDescriptor<CodeEntry>(predicate: #Predicate { $0.id == id })
        descriptor.fetchLimit = 1
        do {
            return try context.fetch(descriptor).first
        } catch {
            Logger.persistence.error("Lecture de l'entrée impossible : \(error.localizedDescription)")
            return nil
        }
    }

    private func save(_ entries: [CodeEntry], _ kind: ChangeKind) {
        do {
            try context.save()
            for observer in onChange { observer(entries, kind) }
        } catch {
            alerts.show(error, title: String(localized: "L’historique n’a pas pu être enregistré"))
        }
    }
}
