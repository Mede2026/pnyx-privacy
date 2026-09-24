import Foundation
import Observation
import OSLog
import QRCore
import SwiftData

/// Services partagés de l'app Mac. Même interface que sur iPhone pour les vues communes.
@MainActor
@Observable
final class AppServices {
    static let shared = AppServices()

    let settings: AppSettings
    let alerts = AlertCenter()
    let spotlight = SpotlightIndexer()
    let macLink = MacLinkServer()
    let safeBrowsing: MacSafeBrowsing
    let router = MacRouter()
    private(set) var container: ModelContainer
    private(set) var store: EntryStore

    /// Sélection de la fenêtre principale.
    var sidebar: SidebarItem? = .allCodes
    var selectedEntryID: UUID?
    var isGeneratorPresented = false
    /// Texte collé (⌘V) à préremplir dans le générateur.
    var generatorPrefill: String?
    var isScannerPresented = false
    var isExportPresented = false
    var isSearchFocused = false

    enum SidebarItem: Hashable {
        case allCodes, favorites, scanned, generated, trash, map
        case folder(UUID)

        var filter: HistoryFilter {
            var filter = HistoryFilter()
            switch self {
            case .favorites: filter.favoritesOnly = true
            case .scanned: filter.origin = .scanned
            case .generated: filter.origin = .generated
            case .trash: filter.inTrash = true
            case .folder(let id): filter.folderID = id
            case .allCodes, .map: break
            }
            return filter
        }
    }

    private init() {
        let settings = AppSettings()
        self.settings = settings
        safeBrowsing = MacSafeBrowsing(settings: settings)
        let container = Self.makeContainer(cloudSync: settings.iCloudSync)
        self.container = container
        store = EntryStore(context: container.mainContext, alerts: alerts)
        configure()
        AppModelContainer.seedDefaults(in: container.mainContext)
        AppModelContainer.purgeTrash(in: container.mainContext)
        #if DEBUG
        TestDataSeeder.seedIfRequested(into: container.mainContext)
        DemoData.insertIfRequested(into: container.mainContext)
        #endif
        spotlight.reindexIfNeeded(context: container.mainContext)
        safeBrowsing.settingChanged()
    }

    func setCloudSync(_ enabled: Bool) {
        settings.iCloudSync = enabled
        container = Self.makeContainer(cloudSync: enabled)
        store = EntryStore(context: container.mainContext, alerts: alerts)
        configure()
    }

    private func configure() {
        ShortcutParameters.refreshSoon()
        store.onChange.append { [spotlight] entries, kind in
            spotlight.update(entries, kind: kind)
            ShortcutParameters.refreshSoon()
        }
    }

    /// Repli local puis en mémoire : l'app ne plante jamais à l'ouverture de la base.
    private static func makeContainer(cloudSync: Bool) -> ModelContainer {
        for attempt in [cloudSync, false] {
            do {
                return try AppModelContainer.make(cloudSync: attempt)
            } catch {
                Logger.persistence.error("Conteneur impossible (synchro \(attempt)) : \(error.localizedDescription)")
            }
        }
        do {
            return try AppModelContainer.make(cloudSync: false, inMemory: true)
        } catch {
            fatalError("Schéma SwiftData invalide : \(error)")
        }
    }
}
