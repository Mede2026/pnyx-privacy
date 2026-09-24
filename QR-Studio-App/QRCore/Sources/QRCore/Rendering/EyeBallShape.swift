import CoreGraphics
import Foundation

/// Forme du centre des yeux (bloc de 3 × 3 modules).
public enum EyeBallShape: String, CaseIterable, Codable, Sendable, Identifiable {
    case square, rounded, circle, diamond
    public var id: String { rawValue }
}
