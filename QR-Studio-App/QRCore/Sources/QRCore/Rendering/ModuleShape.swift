import CoreGraphics
import Foundation

/// Forme des modules de données.
public enum ModuleShape: String, CaseIterable, Codable, Sendable, Identifiable {
    case square
    case rounded
    case circle
    case diamond
    /// Carrés à coins liés : les coins ne s'arrondissent que là où aucun voisin ne touche.
    case connected

    public var id: String { rawValue }
}
