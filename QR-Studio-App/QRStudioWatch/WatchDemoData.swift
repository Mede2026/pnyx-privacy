#if DEBUG
import Foundation
import OSLog
import QRCore
import SwiftData

/// Données de démonstration pour le simulateur (build Debug) : lancer avec « -QRStudioDemo ».
/// Le simulateur n'a pas de compte iCloud : sans cela, la liste de la montre reste vide.
@MainActor
enum WatchDemoData {
    static func insertIfRequested(into context: ModelContext) {
        guard ProcessInfo.processInfo.arguments.contains("-QRStudioDemo") else { return }
        do {
            guard try context.fetchCount(FetchDescriptor<CodeEntry>()) == 0 else { return }
            let card = CodeEntry(rawValue: "CARTE-0042-7781", symbology: .code128, contentType: .text, origin: .generated)
            card.label = "Carte de fidélité"
            card.isPrimary = true
            card.isFavorite = true
            let wifi = CodeEntry(rawValue: "WIFI:T:WPA;S:Maison;P:motdepasse;;", symbology: .qr, contentType: .wifi,
                                 origin: .generated)
            wifi.label = "Wi-Fi maison"
            wifi.isFavorite = true
            let product = CodeEntry(rawValue: "4006381333931", symbology: .ean13, contentType: .product, origin: .scanned)
            let site = CodeEntry(rawValue: "https://qrstudio.app", symbology: .qr, contentType: .url, origin: .scanned)
            [card, wifi, product, site].forEach(context.insert)
            try context.save()
        } catch {
            Logger.persistence.error("Données de démonstration impossibles : \(error.localizedDescription)")
        }
    }
}
#endif
