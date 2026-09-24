import Foundation
import OSLog

/// Verdict d'une vérification.
public enum SafeBrowsingVerdict: Sendable, Equatable {
    case safe
    case unsafe(ThreatType)
    /// Pas de base locale (option coupée, pas de clé, jamais téléchargée) : aucune affirmation.
    case unknown
}
