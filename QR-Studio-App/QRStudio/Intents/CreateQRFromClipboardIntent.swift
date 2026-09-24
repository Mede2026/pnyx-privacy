import AppIntents
import Foundation
import QRCore
import SwiftUI

/// Crée un QR à partir du contenu du presse-papier.
struct CreateQRFromClipboardIntent: AppIntent {
    static let title: LocalizedStringResource = "Créer un QR à partir du presse-papier"
    static let description = IntentDescription("Crée un code QR avec le texte ou le lien copié.")

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView & ReturnsValue<CodeEntity> {
        let text = Pasteboard.readText() ?? ""
        guard !text.isEmpty else { throw IntentSupport.IntentError.emptyClipboard }
        return try await IntentSupport.createQR(from: text)
    }
}
