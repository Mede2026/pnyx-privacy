import CoreGraphics
import Foundation

/// Description vectorielle d'un code, indépendante du format de sortie.
/// Unités : 1 = un module ; origine en haut à gauche, y vers le bas (comme SVG).
///
/// La même description produit le PNG, le JPEG, le PDF vectoriel et le SVG,
/// ce qui garantit que les quatre formats sont identiques.
public struct CodeDrawing: @unchecked Sendable {
    // @unchecked : CGPath et Data sont immuables une fois construits.

    public enum Fill: Sendable, Hashable {
        case solid(RGBAColor)
        case linear(RGBAColor, RGBAColor, start: CGPoint, end: CGPoint)
        case radial(RGBAColor, RGBAColor, center: CGPoint, radius: CGFloat)
    }

    public struct Layer {
        public var path: CGPath
        public var fill: Fill
        public var evenOdd: Bool
    }

    public struct ImageItem {
        public var pngData: Data
        public var rect: CGRect
    }

    public struct TextItem {
        public var text: String
        /// Centre horizontal et ligne de base.
        public var center: CGPoint
        public var fontSize: CGFloat
        public var color: RGBAColor
        public var bold: Bool
    }

    public var size: CGSize
    public var background: RGBAColor?
    public var backgroundCornerRadius: CGFloat = 0
    public var layers: [Layer] = []
    public var images: [ImageItem] = []
    public var texts: [TextItem] = []

    public init(size: CGSize, background: RGBAColor?) {
        self.size = size
        self.background = background
    }

    public var aspectRatio: CGFloat {
        size.height > 0 ? size.width / size.height : 1
    }

    /// Taille en pixels pour une largeur donnée, en conservant les proportions.
    public func pixelSize(forWidth width: Int) -> (width: Int, height: Int) {
        let height = max(1, Int((CGFloat(width) / aspectRatio).rounded()))
        return (width, height)
    }
}
