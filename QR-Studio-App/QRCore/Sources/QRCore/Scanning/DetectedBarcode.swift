import CoreGraphics
import Foundation

/// Code détecté dans une image ou un flux vidéo, sous forme de valeur Sendable.
public struct DetectedBarcode: Sendable, Hashable, Identifiable {
    public var id: String { payload + "|" + symbology.rawValue }
    public var payload: String
    public var symbology: Symbology
    /// Rectangle normalisé (0…1), origine en bas à gauche comme dans Vision.
    public var boundingBox: CGRect

    public init(payload: String, symbology: Symbology, boundingBox: CGRect = .zero) {
        self.payload = payload
        self.symbology = symbology
        self.boundingBox = boundingBox
    }
}
