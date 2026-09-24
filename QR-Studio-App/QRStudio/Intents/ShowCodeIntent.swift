import AppIntents
import Foundation
import QRCore
import SwiftUI

/// Affiche un code enregistré, sans lancer l'app.
struct ShowCodeIntent: AppIntent {
    static let title: LocalizedStringResource = "Afficher un code"
    static let description = IntentDescription("Affiche un code enregistré, par exemple une carte de fidélité.")

    @Parameter(title: "Code")
    var code: CodeEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Afficher \(\.$code)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        guard let entry = AppServices.shared.store.fetchEntry(id: code.id) else {
            throw IntentSupport.IntentError.notFound
        }
        let image = try await IntentSupport.image(for: entry.previewRequest)
        return .result(dialog: IntentDialog(stringLiteral: entry.displayTitle)) {
            CodeSnippetView(image: image, title: entry.displayTitle)
        }
    }
}
