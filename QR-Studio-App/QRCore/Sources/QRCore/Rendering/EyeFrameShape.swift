import CoreGraphics
import Foundation

/// Forme du contour des yeux (anneau de 7 × 7 modules, épaisseur 1 module).
public enum EyeFrameShape: String, CaseIterable, Codable, Sendable, Identifiable {
    case square, rounded, circle
    public var id: String { rawValue }
}
