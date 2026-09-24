import CoreSpotlight
import QRCore
import SwiftData
import SwiftUI

@main
struct QRStudioMacApp: App {
    @State private var services = AppServices.shared

    var body: some Scene {
        WindowGroup("QR Studio") {
            MacSplitView()
                .environment(services)
                .environment(services.settings)
                .environment(services.alerts)
                .environment(services.macLink)
                .modelContainer(services.container)
                .frame(minWidth: 960, minHeight: 620)
                .onContinueUserActivity(CSSearchableItemActionType) { activity in
                    // Résultat Spotlight choisi : on sélectionne le code.
                    if let id = SpotlightIndexer.entryID(from: activity) { services.router.showEntry(id) }
                }
        }
        .commands { MacCommands(services: services) }

        Window("Scans reçus", id: "received") {
            ReceivedScansView()
                .environment(services.macLink)
                .environment(services.alerts)
                .alertHost()
        }

        Window("Aide de QR Studio", id: "help") {
            MacHelpView()
        }
        .windowResizability(.contentSize)

        Settings {
            MacSettingsView()
                .environment(services)
                .environment(services.macLink)
                .environment(services.settings)
                .environment(services.alerts)
                .modelContainer(services.container)
        }
    }
}
