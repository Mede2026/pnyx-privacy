import CoreGraphics
import Foundation

/// Mise en page d'un code-barres linéaire : barres noires, zone silencieuse obligatoire
/// de chaque côté, chiffres lisibles sous le code.
enum LinearBarcodeDrawer {
    static func drawing(for symbol: LinearSymbol, style: StyleConfig) -> CodeDrawing {
        let quietLeft = CGFloat(symbol.quietLeft)
        let barsWidth = CGFloat(symbol.modules.count)
        let width = quietLeft + barsWidth + CGFloat(symbol.quietRight)

        // Proportions proches de la norme EAN (barres ≈ 70 modules de haut pour 95 de large).
        let topMargin: CGFloat = 6
        let barHeight: CGFloat = max(50, barsWidth * 0.55)
        let fontSize: CGFloat = 10
        let guardExtension: CGFloat = symbol.digitsBetweenGuards ? fontSize * 0.55 : 0
        let textGap: CGFloat = symbol.digitsBetweenGuards ? 1 : 3
        let height = topMargin + barHeight + textGap + fontSize + 4

        var drawing = CodeDrawing(size: CGSize(width: width, height: height), background: style.background)

        let path = CGMutablePath()
        var index = 0
        while index < symbol.modules.count {
            guard symbol.modules[index] else { index += 1; continue }
            // Regroupe les modules noirs contigus de même hauteur en une seule barre.
            let isGuard = symbol.guards[index]
            var end = index
            while end < symbol.modules.count, symbol.modules[end], symbol.guards[end] == isGuard { end += 1 }
            let barBottom = barHeight + (isGuard ? guardExtension : 0)
            path.addRect(CGRect(x: quietLeft + CGFloat(index), y: topMargin,
                                width: CGFloat(end - index), height: barBottom))
            index = end
        }
        let fill: CodeDrawing.Fill = .solid(style.foreground)
        drawing.layers.append(.init(path: path, fill: fill, evenOdd: false))

        let baseline = topMargin + barHeight + textGap + fontSize * 0.8
        for caption in symbol.captions {
            let size = caption.small ? fontSize * 0.75 : fontSize
            let available = CGFloat(caption.to - caption.from)
            let measured = CodeDrawing.textWidth(caption.text, fontSize: size, bold: false)
            let fitted = measured > available && available > 0 ? size * available / measured : size
            let centerX = quietLeft + CGFloat((caption.from + caption.to) / 2)
            drawing.texts.append(.init(
                text: caption.text,
                center: CGPoint(x: centerX, y: baseline),
                fontSize: fitted,
                color: style.foreground,
                bold: false
            ))
        }
        return drawing
    }
}
