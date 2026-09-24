import AppIntents
import Foundation

/// Les phrases « Montre \(code) dans QR Studio » reposent sur les noms des codes :
/// Siri doit les réapprendre quand l'historique change. Regroupé pour ne pas le faire à chaque frappe.
@MainActor
enum ShortcutParameters {
    private static var pending: Task<Void, Never>?

    static func refreshSoon() {
        pending?.cancel()
        pending = Task {
            guard await pause(.seconds(3)) else { return }
            QRStudioShortcuts.updateAppShortcutParameters()
        }
    }
}
