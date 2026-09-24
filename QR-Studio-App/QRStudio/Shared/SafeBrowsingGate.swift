import BackgroundTasks
import Foundation
import Observation
import OSLog
import QRCore

/// Porte d'entrée de Safe Browsing dans l'app : respecte le réglage, la présence de la clé
/// et garde les verdicts en mémoire pour ne pas refaire la vérification.
@MainActor
@Observable
final class SafeBrowsingGate {
    static let refreshTaskID = "app.qrstudio.safebrowsing.refresh"

    private let settings: AppSettings
    @ObservationIgnored private var verdicts: [URL: SafeBrowsingVerdict] = [:]

    init(settings: AppSettings) {
        self.settings = settings
    }

    var isEnabled: Bool { settings.safeBrowsing }
    var hasAPIKey: Bool { SafeBrowsingClient.apiKey != nil }

    /// Verdict pour une URL. Sans clé ou option coupée : .unknown, et les liens s'ouvrent
    /// dans Safari intégré, qui avertit lui-même des sites frauduleux.
    func verdict(for url: URL) async -> SafeBrowsingVerdict {
        guard isEnabled, let key = SafeBrowsingClient.apiKey else { return .unknown }
        if let cached = verdicts[url] { return cached }
        let verdict = await SafeBrowsingClient.shared.check(url, apiKey: key)
        verdicts[url] = verdict
        return verdict
    }

    /// Mise à jour de la base locale, au rythme demandé par l'API.
    func refresh() async {
        guard isEnabled, let key = SafeBrowsingClient.apiKey else { return }
        do {
            try await SafeBrowsingClient.shared.updateIfNeeded(apiKey: key)
        } catch {
            Logger.general.error("Mise à jour Safe Browsing impossible : \(error.localizedDescription)")
        }
        schedule()
    }

    /// Programme la prochaine mise à jour en tâche de fond (BGAppRefreshTask).
    func schedule() {
        guard isEnabled, hasAPIKey else {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskID)
            return
        }
        Task {
            let earliest = await SafeBrowsingClient.shared.earliestNextUpdate
            let request = BGAppRefreshTaskRequest(identifier: Self.refreshTaskID)
            request.earliestBeginDate = max(earliest, .now.addingTimeInterval(15 * 60))
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                Logger.general.info("Tâche de fond non programmée : \(error.localizedDescription)")
            }
        }
    }

    /// Option coupée : la base locale est effacée.
    func disable() {
        verdicts = [:]
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: Self.refreshTaskID)
        Task {
            do {
                try await SafeBrowsingClient.shared.reset()
            } catch {
                Logger.general.error("Base Safe Browsing non effacée : \(error.localizedDescription)")
            }
        }
    }
}
