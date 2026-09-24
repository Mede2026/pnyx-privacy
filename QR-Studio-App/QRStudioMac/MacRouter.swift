import AppKit
import Foundation

/// Navigation demandée de l'extérieur (Siri, Raccourcis, Spotlight) : même interface que le routeur iPhone.
@MainActor
final class MacRouter {
    func showEntry(_ id: UUID) {
        let services = AppServices.shared
        // Un code mis à la corbeille n'apparaît que dans « Supprimés récemment ».
        let isTrashed = services.store.fetchEntry(id: id)?.deletedAt != nil
        services.sidebar = isTrashed ? .trash : .allCodes
        services.selectedEntryID = id
        NSApp.activate()
    }

    func openScanner() {
        AppServices.shared.isScannerPresented = true
        NSApp.activate()
    }
}
