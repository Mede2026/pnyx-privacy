import Foundation
import UIKit

/// Délégué de scène : reçoit les actions rapides de l'icône (au lancement ou app ouverte).
final class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let item = connectionOptions.shortcutItem { handle(item) }
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem) async -> Bool {
        handle(shortcutItem)
        return true
    }

    private func handle(_ item: UIApplicationShortcutItem) {
        guard let link = DeepLink(shortcutType: item.type) else { return }
        // Laisse l'interface s'installer avant de naviguer.
        Task {
            _ = await pause(.milliseconds(300))
            link.open(in: AppServices.shared)
        }
    }
}
