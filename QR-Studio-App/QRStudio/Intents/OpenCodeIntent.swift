import AppIntents
import Foundation
import QRCore
import SwiftUI

/// Ouvre un code dans l'app (résultat Visual Intelligence, Raccourcis).
struct OpenCodeIntent: OpenIntent {
    static let title: LocalizedStringResource = "Ouvrir un code"
    static let description = IntentDescription("Ouvre un code enregistré dans QR Studio.")

    @Parameter(title: "Code")
    var target: CodeEntity

    @MainActor
    func perform() async throws -> some IntentResult {
        AppServices.shared.router.showEntry(target.id)
        return .result()
    }
}
