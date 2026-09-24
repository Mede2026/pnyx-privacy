import QRCore
import SwiftData
import SwiftUI

@main
struct QRStudioApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            // Pendant les tests unitaires, l'app hôte n'ouvre pas sa base CloudKit :
            // deux conteneurs des mêmes modèles dans un processus font échouer SwiftData.
            if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
                Color.clear
            } else {
                MainAppView()
            }
        }
        // Mise à jour de la base Safe Browsing en tâche de fond (BGAppRefreshTask).
        .backgroundTask(.appRefresh(SafeBrowsingGate.refreshTaskID)) {
            await Self.refreshSafeBrowsing()
        }
    }

    @MainActor
    private static func refreshSafeBrowsing() async {
        await AppServices.shared.safeBrowsing.refresh()
    }
}
