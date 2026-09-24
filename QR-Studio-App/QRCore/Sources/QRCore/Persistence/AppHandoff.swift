import Foundation

/// Passage de relais d'une extension vers l'app. Une extension de partage ne peut pas ouvrir l'app :
/// elle dépose la demande dans le groupe d'apps, et l'app la reprend à sa prochaine ouverture.
public enum AppHandoff: Equatable, Sendable {
    /// Ouvrir le générateur, prérempli avec ce contenu.
    case generator(String)
    /// Ouvrir le détail d'un code enregistré par l'extension.
    case entry(UUID)

    private static let key = "pendingHandoff"
    /// Au-delà, la demande est oubliée : l'utilisateur a manifestement changé d'idée.
    public static let maxAge: TimeInterval = 10 * 60

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: AppModelContainer.appGroupIdentifier)
    }

    public func post() {
        let (kind, value): (String, String) = switch self {
        case .generator(let text): ("generator", text)
        case .entry(let id): ("entry", id.uuidString)
        }
        Self.defaults?.set(["kind": kind, "value": value, "date": Date.now.timeIntervalSince1970], forKey: Self.key)
    }

    /// Reprend la demande en attente (une seule fois).
    public static func consume(now: Date = .now) -> AppHandoff? {
        guard let defaults, let stored = defaults.dictionary(forKey: key) else { return nil }
        defaults.removeObject(forKey: key)
        guard let kind = stored["kind"] as? String, let value = stored["value"] as? String,
              let date = stored["date"] as? TimeInterval,
              now.timeIntervalSince1970 - date < maxAge else { return nil }
        switch kind {
        case "generator": return .generator(value)
        case "entry": return UUID(uuidString: value).map(AppHandoff.entry)
        default: return nil
        }
    }
}
