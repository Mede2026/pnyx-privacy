import Foundation
import Observation
import QRCore

/// État de navigation, partagé entre la disposition iPhone (onglets) et iPad (barre latérale).
@MainActor
@Observable
final class AppRouter {
    enum Tab: Hashable {
        case scanner
        case create
        case history
        case settings
    }

    /// Sections de la barre latérale en disposition large.
    enum SidebarItem: Hashable {
        case create
        case allCodes
        case favorites
        case scanned
        case generated
        case trash
        case folder(UUID)
    }

    var selectedTab: Tab = .scanner
    var sidebarSelection: SidebarItem? = .allCodes
    /// Entrée affichée dans le détail (ouverte depuis Spotlight, un raccourci ou la liste).
    var selectedEntryID: UUID?
    /// Type de contenu choisi dans le générateur.
    var generatorType: ContentType?
    /// Contenu à préremplir dans le générateur (extension de partage, raccourci).
    var generatorPrefill: String?
    var isScannerPresented = false
    var isSettingsPresented = false
    /// Recherche à appliquer à l'historique (Visual Intelligence, « Plus de résultats »).
    var pendingSearch: String?

    func openScanner() {
        selectedTab = .scanner
        isScannerPresented = true
    }

    func showEntry(_ id: UUID) {
        selectedTab = .history
        sidebarSelection = .allCodes
        selectedEntryID = id
    }

    func searchHistory(for text: String) {
        selectedTab = .history
        sidebarSelection = .allCodes
        pendingSearch = text
    }

    func createCode(type: ContentType, prefill: String? = nil) {
        selectedTab = .create
        sidebarSelection = .create
        generatorPrefill = prefill
        generatorType = type
    }
}

extension HistoryFilter {
    init(sidebar: AppRouter.SidebarItem) {
        switch sidebar {
        case .favorites: favoritesOnly = true
        case .scanned: origin = .scanned
        case .generated: origin = .generated
        case .trash: inTrash = true
        case .folder(let id): folderID = id
        case .allCodes, .create: break
        }
    }
}
