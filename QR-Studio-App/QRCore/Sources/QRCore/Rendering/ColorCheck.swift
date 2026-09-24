import CoreGraphics
import Foundation

/// Résultat des garde-fous de lisibilité.
public struct ColorCheck: Sendable, Equatable {
    /// Ratio de contraste le plus faible entre une couleur de premier plan et le fond.
    public var contrastRatio: Double
    /// Garde-fou n° 3 : sous 4:1, la combinaison est bloquée.
    public var isContrastTooLow: Bool
    /// Garde-fou n° 4 : modules plus clairs que le fond (avertissement, non bloquant).
    public var isInverted: Bool
}
