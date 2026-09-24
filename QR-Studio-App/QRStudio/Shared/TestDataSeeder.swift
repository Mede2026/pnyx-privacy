#if DEBUG
import Foundation
import OSLog
import QRCore
import SwiftData

/// Jeu de données de test (build Debug seulement) : lancer avec « -QRStudioSeed 2000 ».
/// Une app testée avec 12 entrées ne révèle aucun problème de défilement ni de mémoire.
@MainActor
enum TestDataSeeder {
    static func seedIfRequested(into context: ModelContext) {
        let arguments = ProcessInfo.processInfo.arguments
        guard let flag = arguments.firstIndex(of: "-QRStudioSeed"), flag + 1 < arguments.count,
              let count = Int(arguments[flag + 1]), count > 0 else { return }
        do {
            let existing = try context.fetchCount(FetchDescriptor<CodeEntry>())
            guard existing < count else { return }
            let samples: [(String, ContentType, Symbology)] = [
                ("https://exemple.com/produit/", .url, .qr),
                ("WIFI:T:WPA;S:Chalet;P:motdepasse;;", .wifi, .qr),
                ("Note de visite n°", .text, .qr),
                ("400638133393", .product, .ean13),
                ("BEGIN:VCARD\nVERSION:3.0\nFN:Contact\nEND:VCARD", .contact, .qr),
                ("geo:45.5,-73.5", .location, .qr)
            ]
            for index in existing..<count {
                let (base, type, symbology) = samples[index % samples.count]
                let payload = type == .product
                    ? base + String(GTIN.expectedCheckDigit(for: base + "0") ?? 0)
                    : "\(base)\(index)"
                let entry = CodeEntry(rawValue: payload, symbology: symbology, contentType: type,
                                      origin: index.isMultiple(of: 3) ? .generated : .scanned)
                entry.createdAt = Date.now.addingTimeInterval(Double(-index) * 4 * 3600)
                entry.isFavorite = index.isMultiple(of: 17)
                if index.isMultiple(of: 5) {
                    entry.latitude = 45.5 + Double(index % 40) / 100
                    entry.longitude = -73.6 + Double(index % 30) / 100
                }
                context.insert(entry)
            }
            try context.save()
            Logger.persistence.info("Jeu de test : \(count - existing) entrées ajoutées")
        } catch {
            Logger.persistence.error("Jeu de test impossible : \(error.localizedDescription)")
        }
    }
}
#endif
