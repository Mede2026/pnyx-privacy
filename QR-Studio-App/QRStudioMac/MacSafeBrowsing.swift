import AppKit
import Foundation
import Observation
import OSLog
import QRCore

/// Safe Browsing sur Mac : même base locale que sur iPhone, mise à jour par NSBackgroundActivityScheduler
/// (BGTaskScheduler n'existe pas sur macOS) et avertissement par une alerte avant l'ouverture.
@MainActor
@Observable
final class MacSafeBrowsing {
    static let advisoryURL = URL(string: "https://developers.google.com/safe-browsing/v4/advisory")

    private let settings: AppSettings
    @ObservationIgnored private var verdicts: [URL: SafeBrowsingVerdict] = [:]
    @ObservationIgnored private let scheduler: NSBackgroundActivityScheduler = {
        let scheduler = NSBackgroundActivityScheduler(identifier: "app.qrstudio.mac.safebrowsing.refresh")
        scheduler.repeats = true
        scheduler.interval = 30 * 60
        scheduler.qualityOfService = .utility
        return scheduler
    }()

    init(settings: AppSettings) {
        self.settings = settings
    }

    var isActive: Bool { settings.safeBrowsing && SafeBrowsingClient.apiKey != nil }

    /// À appeler au lancement et quand le réglage change.
    func settingChanged() {
        scheduler.invalidate()
        guard isActive else {
            disable()
            return
        }
        Task { await refresh() }
        // L'API impose son propre délai minimal : updateIfNeeded ne télécharge rien avant l'heure.
        scheduler.schedule { completion in
            Task { @MainActor in
                await AppServices.shared.safeBrowsing.refresh()
                completion(.finished)
            }
        }
    }

    func refresh() async {
        guard isActive, let key = SafeBrowsingClient.apiKey else { return }
        do {
            try await SafeBrowsingClient.shared.updateIfNeeded(apiKey: key)
        } catch {
            Logger.general.error("Mise à jour Safe Browsing impossible : \(error.localizedDescription)")
        }
    }

    /// Verdict mis en mémoire : .unknown si l'option est coupée ou sans clé.
    func verdict(for url: URL) async -> SafeBrowsingVerdict {
        guard isActive, let key = SafeBrowsingClient.apiKey else { return .unknown }
        if let cached = verdicts[url] { return cached }
        let verdict = await SafeBrowsingClient.shared.check(url, apiKey: key)
        verdicts[url] = verdict
        return verdict
    }

    /// Ouvre un lien web après vérification ; un lien signalé demande confirmation.
    func open(_ url: URL, using open: @escaping @MainActor (URL) -> Void) {
        let scheme = url.scheme?.lowercased() ?? ""
        guard isActive, scheme == "http" || scheme == "https" else {
            open(url)
            return
        }
        Task {
            guard case .unsafe(let threat) = await verdict(for: url) else {
                open(url)
                return
            }
            if confirmOpening(url, threat: threat) { open(url) }
        }
    }

    /// Alerte critique : « Ne pas ouvrir » est le bouton par défaut.
    private func confirmOpening(_ url: URL, threat: ThreatType) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .critical
        alert.messageText = String(localized: "Lien signalé comme dangereux")
        alert.informativeText = [
            threat.reason,
            url.host(percentEncoded: false) ?? url.absoluteString,
            String(localized: "Avertissement fourni par Google Safe Browsing.")
        ].joined(separator: "\n\n")
        alert.addButton(withTitle: String(localized: "Ne pas ouvrir"))
        alert.addButton(withTitle: String(localized: "Ouvrir quand même"))
        alert.addButton(withTitle: String(localized: "En savoir plus"))
        switch alert.runModal() {
        case .alertSecondButtonReturn:
            return true
        case .alertThirdButtonReturn:
            if let advisory = Self.advisoryURL { NSWorkspace.shared.open(advisory) }
            return false
        default:
            return false
        }
    }

    private func disable() {
        verdicts = [:]
        Task {
            do {
                try await SafeBrowsingClient.shared.reset()
            } catch {
                Logger.general.error("Base Safe Browsing non effacée : \(error.localizedDescription)")
            }
        }
    }
}
