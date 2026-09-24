import Foundation
import Observation
import QRCore

/// Symbologies actives en mode lot.
enum BatchSymbologyPreset: String, CaseIterable, Identifiable {
    /// EAN-13, EAN-8, UPC-E et Code 128 : l'inventaire de produits.
    case retail
    case all
    /// Formats cochés dans les réglages, pour les cas particuliers.
    case custom

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .retail: "Produits en magasin"
        case .all: "Tous les formats"
        case .custom: "Formats choisis"
        }
    }
}
