import AppIntents
import Foundation
import QRCore
import SwiftData
import SwiftUI

/// « Montre mon code Wi-Fi dans QR Studio » : le code Wi-Fi principal, sinon favori, sinon le plus récent.
struct ShowWiFiIntent: AppIntent {
    static let title: LocalizedStringResource = "Afficher mon code Wi-Fi"
    static let description = IntentDescription("Affiche votre code Wi-Fi pour qu’un invité le scanne.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let entry = Self.bestWiFiEntry() else { throw IntentSupport.IntentError.noWiFi }
        let image = try await IntentSupport.image(for: entry.previewRequest)
        return .result(dialog: IntentDialog(stringLiteral: entry.displayTitle)) {
            CodeSnippetView(image: image, title: entry.displayTitle)
        }
    }

    @MainActor
    static func bestWiFiEntry() -> CodeEntry? {
        let types = [ContentType.wifi.rawValue, ContentType.wifiEnterprise.rawValue]
        let descriptor = FetchDescriptor<CodeEntry>(
            predicate: #Predicate { $0.deletedAt == nil && types.contains($0.contentType) },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let entries = try AppServices.shared.container.mainContext.fetch(descriptor)
            return entries.first(where: \.isPrimary) ?? entries.first(where: \.isFavorite) ?? entries.first
        } catch {
            return nil
        }
    }
}
