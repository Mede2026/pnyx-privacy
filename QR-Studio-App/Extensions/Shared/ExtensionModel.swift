import Foundation
import Observation
import OSLog
import QRCore
import SwiftData
import UIKit
import UniformTypeIdentifiers

/// Logique commune aux extensions : lire l'élément reçu, décoder ou préparer un QR, écrire dans la base.
/// Une extension a peu de mémoire : ni moteur de rendu stylisé, ni base Safe Browsing ici.
@MainActor
@Observable
final class ExtensionModel {
    enum State {
        case loading
        case codes([DetectedBarcode])
        case text(String)
        case failed(String)
    }

    private(set) var state: State = .loading
    private(set) var savedPayloads: Set<String> = []
    @ObservationIgnored private var savedIDs: [String: UUID] = [:]
    var toast: String?
    @ObservationIgnored private var container: ModelContainer?

    /// Lit le premier élément utile : image, lien ou texte.
    func load(_ items: [NSExtensionItem]) async {
        let providers = items.flatMap { $0.attachments ?? [] }
        do {
            if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.image.identifier) }) {
                let data = try await provider.loadData(for: .image)
                let codes = try ImageBarcodeDecoder.decode(imageData: data)
                state = codes.isEmpty ? .failed(String(localized: "Aucun code n’a été trouvé dans cette image.")) : .codes(codes)
            } else if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
                let data = try await provider.loadData(for: .url)
                let text = URL(dataRepresentation: data, relativeTo: nil)?.absoluteString ?? String(decoding: data, as: UTF8.self)
                state = .text(text)
            } else if let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
                let data = try await provider.loadData(for: .plainText)
                state = .text(String(decoding: data, as: UTF8.self))
            } else {
                state = .failed(String(localized: "Cet élément ne contient ni image, ni lien, ni texte."))
            }
        } catch {
            Logger.general.error("Élément partagé illisible : \(error.localizedDescription)")
            state = .failed(String(localized: "Cet élément n’a pas pu être lu."))
        }
    }

    /// Écrit l'entrée dans la base commune (groupe d'apps). Elle apparaîtra dans l'app et sera synchronisée.
    @discardableResult
    func save(payload: String, symbology: Symbology, origin: CodeEntry.Origin) -> UUID? {
        if let id = savedIDs[payload] { return id }
        do {
            let context = try sharedContainer().mainContext
            let parsed = ScannedContentParser.parse(payload, symbology: symbology)
            let entry = CodeEntry(rawValue: payload, symbology: symbology, contentType: parsed.contentType, origin: origin)
            if case .product(let product) = parsed { entry.productCode = product.gtin }
            context.insert(entry)
            try context.save()
            savedPayloads.insert(payload)
            savedIDs[payload] = entry.id
            toast = String(localized: "Enregistré dans l’historique")
            return entry.id
        } catch {
            Logger.persistence.error("Enregistrement impossible depuis l’extension : \(error.localizedDescription)")
            toast = String(localized: "L’enregistrement a échoué")
            return nil
        }
    }

    /// Enregistre le code puis le confie à l'app, qui l'ouvrira à son prochain lancement.
    func openInApp(payload: String, symbology: Symbology) {
        guard let id = save(payload: payload, symbology: symbology, origin: .scanned) else { return }
        AppHandoff.entry(id).post()
        toast = String(localized: "Ouvrez QR Studio : le code vous y attend.")
    }

    /// Le générateur de l'app s'ouvrira prérempli avec ce contenu.
    func customizeInApp(_ text: String) {
        AppHandoff.generator(text).post()
        toast = String(localized: "Ouvrez QR Studio : le générateur est prêt.")
    }

    func copy(_ text: String) {
        UIPasteboard.general.string = text
        toast = String(localized: "Copié")
    }

    func copy(image: UIImage) {
        UIPasteboard.general.image = image
        toast = String(localized: "Image copiée")
    }

    /// L'extension n'active pas la synchro CloudKit : l'app exportera les changements à sa prochaine ouverture.
    private func sharedContainer() throws -> ModelContainer {
        if let container { return container }
        let made = try AppModelContainer.make(cloudSync: false)
        container = made
        return made
    }
}
