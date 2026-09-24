#if DEBUG
import Foundation
import OSLog
import QRCore
import SwiftData

/// Données de démonstration pour les captures de l'App Store (build Debug) : lancer avec « -QRStudioDemo ».
@MainActor
enum DemoData {
    static func insertIfRequested(into context: ModelContext) {
        guard ProcessInfo.processInfo.arguments.contains("-QRStudioDemo") else { return }
        do {
            guard try context.fetchCount(FetchDescriptor<CodeEntry>()) == 0 else { return }
            let home = Folder(name: "Maison", symbolName: "house.fill", colorHex: "#30D158")
            let work = Folder(name: "Travail", symbolName: "briefcase.fill", colorHex: "#0A84FF")
            let travel = Folder(name: "Voyage", symbolName: "airplane", colorHex: "#FF9F0A")
            [home, work, travel].forEach(context.insert)

            func preset(_ id: String) -> StyleConfig? { StylePresets.all.first { $0.id == id }?.config }
            func add(_ payload: String, _ symbology: Symbology, _ type: ContentType, origin: CodeEntry.Origin,
                     label: String, style: String? = nil, folder: Folder? = nil, hoursAgo: Double,
                     favorite: Bool = false, primary: Bool = false) {
                let entry = CodeEntry(rawValue: payload, symbology: symbology, contentType: type, origin: origin)
                entry.label = label
                entry.folder = folder
                entry.isFavorite = favorite
                entry.isPrimary = primary
                entry.createdAt = Date.now.addingTimeInterval(-hoursAgo * 3600)
                if let config = style.flatMap(preset) { entry.style = CodeStyle(config: config) }
                if type == .product { entry.productCode = GTIN.normalized(payload) }
                context.insert(entry)
            }

            add("WIFI:T:WPA;S:Maison Tremblay;P:soleil-2026;;", .qr, .wifi, origin: .generated,
                label: "Wi-Fi de la maison", style: "ocean", folder: home, hoursAgo: 0.3, favorite: true)
            add("CARTE-0042-7781", .code128, .text, origin: .generated,
                label: "Carte de fidélité", hoursAgo: 1, favorite: true, primary: true)
            add("https://bistro-lumiere.fr/menu", .qr, .url, origin: .scanned,
                label: "Menu du Bistro Lumière", folder: travel, hoursAgo: 2.5)
            add("BEGIN:VCARD\nVERSION:3.0\nN:Tremblay;Marie\nFN:Marie Tremblay\nORG:Atelier Nord\nTEL:+15145550123\nEMAIL:marie@atelier-nord.ca\nEND:VCARD",
                .qr, .contact, origin: .generated, label: "Ma carte de visite", style: "grape", folder: work, hoursAgo: 5)
            add("3017620422003", .ean13, .product, origin: .scanned, label: "Pâte à tartiner", hoursAgo: 8)
            add("BEGIN:VEVENT\nSUMMARY:Réunion d’équipe\nLOCATION:Salle Horizon\nDTSTART:20260924T140000Z\nDTEND:20260924T150000Z\nEND:VEVENT",
                .qr, .event, origin: .scanned, label: "", folder: work, hoursAgo: 26)
            add("geo:45.5075,-73.5536?q=Vieux-Port", .qr, .location, origin: .scanned,
                label: "Vieux-Port de Montréal", folder: travel, hoursAgo: 30)
            add("Bienvenue au chalet ! Le bois est dans la remise.", .qr, .text, origin: .generated,
                label: "Mot d’accueil", style: "forest", folder: home, hoursAgo: 50)
            add("https://qrstudio.app", .qr, .url, origin: .generated,
                label: "Site de QR Studio", style: "liquid", hoursAgo: 75, favorite: true)
            try context.save()
        } catch {
            Logger.persistence.error("Données de démonstration impossibles : \(error.localizedDescription)")
        }
    }
}
#endif
