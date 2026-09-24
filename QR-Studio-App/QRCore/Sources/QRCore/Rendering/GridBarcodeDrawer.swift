import CoreGraphics
import Foundation

/// Mise en page des codes 2D autres que le QR (Aztec, PDF417) : couleurs seulement.
enum GridBarcodeDrawer {
    static func drawing(for matrix: BitMatrix, style: StyleConfig, quietZone: Int) -> CodeDrawing {
        let quiet = CGFloat(quietZone)
        let size = CGSize(width: CGFloat(matrix.width) + quiet * 2, height: CGFloat(matrix.height) + quiet * 2)
        var drawing = CodeDrawing(size: size, background: style.background)
        let path = CGMutablePath()
        for y in 0..<matrix.height {
            var x = 0
            while x < matrix.width {
                guard matrix[x, y] else { x += 1; continue }
                var end = x
                while end < matrix.width, matrix[end, y] { end += 1 }
                path.addRect(CGRect(x: quiet + CGFloat(x), y: quiet + CGFloat(y), width: CGFloat(end - x), height: 1))
                x = end
            }
        }
        drawing.layers.append(.init(path: path, fill: .solid(style.foreground), evenOdd: false))
        return drawing
    }
}
