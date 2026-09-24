import CoreGraphics
import Foundation

public enum Readability: Sendable, Equatable {
    case checking
    case readable
    case unreadable(String)
    /// Relecture impossible à confirmer (simulateur iOS, où la détection Vision est peu fiable).
    case unverified(String)

    /// Vrai si l'enregistrement et l'export sont permis.
    public var allowsUse: Bool {
        switch self {
        case .readable, .unverified: true
        case .checking, .unreadable: false
        }
    }
}
