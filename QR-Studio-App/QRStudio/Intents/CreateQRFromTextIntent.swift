import AppIntents
import Foundation
import QRCore
import SwiftUI

/// Crée un QR à partir d'un texte, sans ouvrir l'app.
struct CreateQRFromTextIntent: AppIntent {
    static let title: LocalizedStringResource = "Créer un QR à partir d’un texte"
    static let description = IntentDescription("Crée un code QR et l’enregistre dans l’historique.")

    @Parameter(title: "Texte", inputOptions: String.IntentInputOptions(multiline: true))
    var text: String

    static var parameterSummary: some ParameterSummary {
        Summary("Créer un QR avec \(\.$text)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView & ReturnsValue<CodeEntity> {
        try await IntentSupport.createQR(from: text)
    }
}
