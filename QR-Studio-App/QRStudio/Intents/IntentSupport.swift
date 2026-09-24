import AppIntents
import Foundation
import QRCore
import SwiftData
import SwiftUI

/// Outils partagés par les intents.
@MainActor
enum IntentSupport {
    enum IntentError: Error, CustomLocalizedStringResourceConvertible {
        case emptyClipboard
        case notFound
        case noScan
        case unreadable
        case noWiFi

        var localizedStringResource: LocalizedStringResource {
            switch self {
            case .emptyClipboard: "Le presse-papier ne contient ni texte ni lien."
            case .notFound: "Ce code n’existe plus."
            case .noScan: "Aucun code n’a encore été scanné."
            case .unreadable: "Le code créé n’a pas pu être relu."
            case .noWiFi: "Aucun code Wi-Fi n’est enregistré."
            }
        }
    }

    static func createQR(from text: String) async throws
        -> some IntentResult & ProvidesDialog & ShowsSnippetView & ReturnsValue<CodeEntity> {
        let request = RenderRequest(payload: text, symbology: .qr)
        // Comme dans l'app : on vérifie que le code se relit avant de le remettre.
        if case .unreadable = await ReadabilityValidator.verify(request) { throw IntentError.unreadable }
        let parsed = ScannedContentParser.parse(text)
        let entry = AppServices.shared.store.recordGenerated(payload: text, symbology: .qr,
                                                             contentType: parsed.contentType, style: nil)
        let image = try await image(for: request)
        return .result(value: CodeEntity(entry), dialog: "Voici votre code QR.") {
            CodeSnippetView(image: image, title: entry.displayTitle)
        }
    }

    static func image(for request: RenderRequest) async throws -> PlatformImage {
        let drawing = try await CodeRenderer.shared.drawing(for: request)
        guard let image = PlatformImage(data: try drawing.pngData(width: 600)) else { throw IntentError.unreadable }
        return image
    }

    static func primaryCode() -> CodeEntry? {
        var descriptor = FetchDescriptor<CodeEntry>(predicate: #Predicate { $0.deletedAt == nil && $0.isPrimary })
        descriptor.fetchLimit = 1
        do {
            return try AppServices.shared.container.mainContext.fetch(descriptor).first
        } catch {
            return nil
        }
    }

    static func lastScan() -> CodeEntry? {
        let scanned = CodeEntry.Origin.scanned.rawValue
        var descriptor = FetchDescriptor<CodeEntry>(
            predicate: #Predicate { $0.deletedAt == nil && $0.origin == scanned },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        do {
            return try AppServices.shared.container.mainContext.fetch(descriptor).first
        } catch {
            return nil
        }
    }
}
