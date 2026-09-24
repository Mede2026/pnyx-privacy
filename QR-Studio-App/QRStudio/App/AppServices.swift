import Foundation
import Observation
import OSLog
import QRCore
import SwiftData
import WidgetKit

/// Services partagés de l'app, injectés dans l'environnement SwiftUI.
@MainActor
@Observable
final class AppServices {
    /// Instance unique : l'app et les App Intents (exécutés dans le processus de l'app)
    /// partagent le même conteneur. Deux conteneurs des mêmes modèles feraient échouer SwiftData.
    static let shared = AppServices()

    let settings: AppSettings
    let alerts = AlertCenter()
    let router = AppRouter()
    let scanner = ScannerModel()
    let feedback: Feedback
    let autoOpener: AutoOpener
    let location = LocationService()
    let spotlight = SpotlightIndexer()
    let safeBrowsing: SafeBrowsingGate
    let macLink = MacLinkClient()
    let payloadIndex = PayloadIndex()
    let webhook: WebhookSender
    private(set) var container: ModelContainer
    private(set) var store: EntryStore

    private init() {
        #if DEBUG
        LaunchTimer.mark("début des services")
        #endif
        let settings = AppSettings()
        self.settings = settings
        feedback = Feedback(settings: settings)
        autoOpener = AutoOpener(settings: settings)
        safeBrowsing = SafeBrowsingGate(settings: settings)
        webhook = WebhookSender(settings: settings)
        autoOpener.safeBrowsing = safeBrowsing
        let container = Self.makeContainer(cloudSync: settings.iCloudSync, alerts: nil)
        self.container = container
        #if DEBUG
        LaunchTimer.mark("base ouverte")
        #endif
        store = EntryStore(context: container.mainContext, alerts: alerts)
        configureServices(rebuildIndex: false)
        AppModelContainer.seedDefaults(in: container.mainContext)
        #if DEBUG
        TestDataSeeder.seedIfRequested(into: container.mainContext)
        DemoData.insertIfRequested(into: container.mainContext)
        LaunchTimer.mark("services prêts")
        #endif
        // Rien de ceci n'est nécessaire au premier écran : on le fait une fois l'app affichée.
        Task { [weak self] in
            guard await pause(.milliseconds(800)), let self else { return }
            self.payloadIndex.rebuild(from: self.container.mainContext)
            AppModelContainer.purgeTrash(in: self.container.mainContext)
            self.spotlight.reindexIfNeeded(context: self.container.mainContext)
            await self.safeBrowsing.refresh()
        }
    }

    /// Bascule la synchro iCloud : le conteneur est recréé, local seulement quand elle est coupée.
    func setCloudSync(_ enabled: Bool) {
        settings.iCloudSync = enabled
        container = Self.makeContainer(cloudSync: enabled, alerts: alerts)
        store = EntryStore(context: container.mainContext, alerts: alerts)
        configureServices()
    }

    private func configureServices(rebuildIndex: Bool = true) {
        if rebuildIndex { payloadIndex.rebuild(from: container.mainContext) }
        ShortcutParameters.refreshSoon()
        store.onChange.append { [spotlight, payloadIndex] entries, kind in
            spotlight.update(entries, kind: kind)
            payloadIndex.update(entries, kind: kind)
            // Le widget du code principal et la complication suivent l'historique.
            WidgetCenter.shared.reloadAllTimelines()
            ShortcutParameters.refreshSoon()
        }
        scanner.store = store
        scanner.feedback = feedback
        scanner.settings = settings
        scanner.autoOpener = autoOpener
        scanner.onScan = { [macLink, webhook] payload, symbology in
            macLink.send(payload: payload, symbology: symbology)
            webhook.scanned(payload, symbology: symbology)
        }
        scanner.locationProvider = { [settings, location] in
            settings.recordsLocation ? location.recentLocation : nil
        }
    }

    /// Ne plante jamais : en cas d'échec, repli local, puis en mémoire avec un message visible.
    private static func makeContainer(cloudSync: Bool, alerts: AlertCenter?) -> ModelContainer {
        do {
            return try AppModelContainer.make(cloudSync: cloudSync)
        } catch {
            Logger.persistence.error("Conteneur principal impossible : \(error.localizedDescription)")
        }
        do {
            return try AppModelContainer.make(cloudSync: false)
        } catch {
            Logger.persistence.error("Conteneur local impossible : \(error.localizedDescription)")
        }
        do {
            let container = try AppModelContainer.make(cloudSync: false, inMemory: true)
            alerts?.show(title: String(localized: "Historique indisponible"),
                         detail: String(localized: "Votre historique n’a pas pu être ouvert. Les nouveaux codes ne seront pas conservés après la fermeture de l’app."))
            return container
        } catch {
            // Un conteneur en mémoire ne peut échouer que si le schéma est invalide : erreur de programmation.
            fatalError("Schéma SwiftData invalide : \(error)")
        }
    }
}
