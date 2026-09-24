import Foundation
import QRCore
import UIKit

/// Liens internes : widgets, actions rapides de l'icône, complication.
/// qrstudio://scan · qrstudio://create · qrstudio://code/<UUID> · qrstudio://last
/// qrstudio://primary · qrstudio://history · qrstudio://settings
enum DeepLink {
    case scan
    /// Générateur, prérempli si le lien porte « ?contenu=… » (Raccourcis, autres apps).
    case create(prefill: String?)
    case code(UUID)
    case lastScan
    case primary
    case history
    case settings

    init?(url: URL) {
        guard url.scheme == "qrstudio" else { return nil }
        switch url.host() {
        case "scan": self = .scan
        case "create":
            let prefill = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "contenu" }?.value
            self = .create(prefill: prefill)
        case "last": self = .lastScan
        case "history": self = .history
        case "settings": self = .settings
        case "code", "primary":
            if let id = UUID(uuidString: url.lastPathComponent) {
                self = .code(id)
            } else if url.host() == "primary" {
                self = .primary
            } else {
                return nil
            }
        default: return nil
        }
    }

    init?(shortcutType: String) {
        switch shortcutType {
        case "app.qrstudio.scan": self = .scan
        case "app.qrstudio.create": self = .create(prefill: nil)
        case "app.qrstudio.last": self = .lastScan
        default: return nil
        }
    }

    @MainActor
    func open(in services: AppServices) {
        switch self {
        case .scan:
            services.router.openScanner()
        case .create(let prefill):
            let isLink = prefill.map { if case .url = ScannedContentParser.parse($0) { true } else { false } } ?? true
            services.router.createCode(type: isLink ? .url : .text, prefill: prefill)
        case .code(let id):
            services.router.showEntry(id)
        case .lastScan:
            if let entry = IntentSupport.lastScan() { services.router.showEntry(entry.id) }
        case .primary:
            if let entry = IntentSupport.primaryCode() { services.router.showEntry(entry.id) }
        case .history:
            services.router.selectedTab = .history
            services.router.sidebarSelection = .allCodes
        case .settings:
            services.router.selectedTab = .settings
            services.router.isSettingsPresented = true
        }
    }
}
