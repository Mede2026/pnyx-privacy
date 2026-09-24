import OSLog
import QRCore
import SwiftData
import SwiftUI
import WidgetKit

@main
struct QRStudioWatchApp: App {
    /// La montre lit sa propre base, synchronisée par CloudKit : aucun iPhone n'est nécessaire à proximité.
    private let container: ModelContainer = {
        do {
            return try AppModelContainer.make(cloudSync: true)
        } catch {
            Logger.persistence.error("Base de la montre impossible : \(error.localizedDescription)")
        }
        // Repli : base locale sur disque, puis en mémoire en dernier recours.
        do {
            return try AppModelContainer.make(cloudSync: false)
        } catch {
            Logger.persistence.error("Base locale de la montre impossible : \(error.localizedDescription)")
        }
        do {
            return try AppModelContainer.make(cloudSync: false, inMemory: true)
        } catch {
            fatalError("Schéma SwiftData invalide : \(error)")
        }
    }()

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            WatchCodeListView()
                #if DEBUG
                .onAppear { WatchDemoData.insertIfRequested(into: container.mainContext) }
                #endif
        }
        .modelContainer(container)
        // La complication relit la base quand l'app se ferme (codes arrivés par iCloud entre-temps).
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { WidgetCenter.shared.reloadAllTimelines() }
        }
    }
}
