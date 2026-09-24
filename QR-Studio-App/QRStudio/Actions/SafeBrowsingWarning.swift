import QRCore
import SwiftUI

/// Lien signalé par Google Safe Browsing : écran rouge plein écran.
/// Obligations de Google respectées : formulation nuancée, attribution avec lien vers l'avis,
/// mention que la protection n'est pas parfaite.
struct SafeBrowsingWarning: Identifiable {
    let id = UUID()
    let url: URL
    let threat: ThreatType
}
