import Foundation
import Observation
import OSLog

/// Erreurs montrées à l'utilisateur : rien n'est avalé en silence.
@MainActor
@Observable
final class AlertCenter {
    struct Message: Identifiable {
        let id = UUID()
        var title: String
        var detail: String
    }

    var current: Message?
    /// Vues capables de présenter une alerte, de la plus ancienne à la plus récente.
    var hosts: [UUID] = []

    func show(_ error: Error, title: String = String(localized: "Un problème est survenu")) {
        Logger.general.error("\(title, privacy: .public) : \(error.localizedDescription, privacy: .public)")
        current = Message(title: title, detail: error.localizedDescription)
    }

    func show(title: String, detail: String) {
        current = Message(title: title, detail: detail)
    }
}
