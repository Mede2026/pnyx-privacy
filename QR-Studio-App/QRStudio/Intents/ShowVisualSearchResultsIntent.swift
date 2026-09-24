#if canImport(VisualIntelligence)
import AppIntents
import CoreVideo
import Foundation
import QRCore
import SwiftData
import VisualIntelligence

/// Bouton « Plus de résultats » : ouvre l'app sur la recherche complète.
@available(iOS 26.0, *)
@AppIntent(schema: .visualIntelligence.semanticContentSearch)
struct ShowVisualSearchResultsIntent {
    var semanticContent: SemanticContentDescriptor

    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        let payloads = CodeVisualQuery.payloads(in: semanticContent)
        AppServices.shared.router.searchHistory(for: payloads.first ?? "")
        return .result()
    }
}
#endif
