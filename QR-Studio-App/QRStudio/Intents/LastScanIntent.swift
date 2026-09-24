import AppIntents
import Foundation
import QRCore
import SwiftUI

/// Renvoie le contenu du dernier scan, utilisable dans un raccourci.
struct LastScanIntent: AppIntent {
    static let title: LocalizedStringResource = "Dernier scan"
    static let description = IntentDescription("Renvoie le contenu du dernier code scanné.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView & ReturnsValue<String> {
        guard let entry = IntentSupport.lastScan() else { throw IntentSupport.IntentError.noScan }
        let dialog = IntentDialog(stringLiteral: "\(entry.contentKind.title) : \(entry.summary)")
        let image = try await IntentSupport.image(for: entry.previewRequest)
        return .result(value: entry.rawValue, dialog: dialog) {
            CodeSnippetView(image: image, title: entry.displayTitle)
        }
    }
}
