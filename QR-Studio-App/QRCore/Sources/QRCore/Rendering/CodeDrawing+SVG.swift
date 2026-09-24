import CoreGraphics
import Foundation

public extension CodeDrawing {
    /// Document SVG autonome. Les logos sont intégrés en base64.
    func svgString(pixelWidth: Int = 1024) -> String {
        let pixels = pixelSize(forWidth: pixelWidth)
        var defs: [String] = []
        var body: [String] = []

        if let background {
            let radius = backgroundCornerRadius > 0 ? " rx=\"\(num(backgroundCornerRadius))\"" : ""
            body.append("<rect width=\"\(num(size.width))\" height=\"\(num(size.height))\"\(radius) \(paint(background))/>")
        }

        for (index, layer) in layers.enumerated() {
            let fill: String
            switch layer.fill {
            case .solid(let color):
                fill = paint(color)
            case .linear(let from, let to, let start, let end):
                let id = "g\(index)"
                defs.append("""
                <linearGradient id="\(id)" gradientUnits="userSpaceOnUse" x1="\(num(start.x))" y1="\(num(start.y))" \
                x2="\(num(end.x))" y2="\(num(end.y))">\(stops(from, to))</linearGradient>
                """)
                fill = "fill=\"url(#\(id))\""
            case .radial(let from, let to, let center, let radius):
                let id = "g\(index)"
                defs.append("""
                <radialGradient id="\(id)" gradientUnits="userSpaceOnUse" cx="\(num(center.x))" cy="\(num(center.y))" \
                r="\(num(radius))">\(stops(from, to))</radialGradient>
                """)
                fill = "fill=\"url(#\(id))\""
            }
            let rule = layer.evenOdd ? " fill-rule=\"evenodd\"" : ""
            body.append("<path d=\"\(pathData(layer.path))\" \(fill)\(rule)/>")
        }

        for item in images {
            let base64 = item.pngData.base64EncodedString()
            body.append("""
            <image x="\(num(item.rect.minX))" y="\(num(item.rect.minY))" width="\(num(item.rect.width))" \
            height="\(num(item.rect.height))" preserveAspectRatio="xMidYMid meet" href="data:image/png;base64,\(base64)"/>
            """)
        }

        for text in texts {
            let weight = text.bold ? " font-weight=\"bold\"" : ""
            body.append("""
            <text x="\(num(text.center.x))" y="\(num(text.center.y))" font-family="-apple-system, Helvetica, Arial, sans-serif" \
            font-size="\(num(text.fontSize))"\(weight) text-anchor="middle" \(paint(text.color))>\(escape(text.text))</text>
            """)
        }

        let defsBlock = defs.isEmpty ? "" : "<defs>\(defs.joined())</defs>"
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" width="\(pixels.width)" height="\(pixels.height)" \
        viewBox="0 0 \(num(size.width)) \(num(size.height))" shape-rendering="geometricPrecision">\(defsBlock)\(body.joined())</svg>

        """
    }

    private func paint(_ color: RGBAColor) -> String {
        let hex = RGBAColor(red: color.red, green: color.green, blue: color.blue).hex
        return color.alpha < 0.999 ? "fill=\"\(hex)\" fill-opacity=\"\(num(color.alpha))\"" : "fill=\"\(hex)\""
    }

    private func stops(_ from: RGBAColor, _ to: RGBAColor) -> String {
        func stop(_ offset: Int, _ color: RGBAColor) -> String {
            let hex = RGBAColor(red: color.red, green: color.green, blue: color.blue).hex
            return "<stop offset=\"\(offset)\" stop-color=\"\(hex)\" stop-opacity=\"\(num(color.alpha))\"/>"
        }
        return stop(0, from) + stop(1, to)
    }

    private func pathData(_ path: CGPath) -> String {
        var parts: [String] = []
        path.applyWithBlock { pointer in
            let element = pointer.pointee
            let p = element.points
            switch element.type {
            case .moveToPoint:
                parts.append("M\(num(p[0].x)) \(num(p[0].y))")
            case .addLineToPoint:
                parts.append("L\(num(p[0].x)) \(num(p[0].y))")
            case .addQuadCurveToPoint:
                parts.append("Q\(num(p[0].x)) \(num(p[0].y)) \(num(p[1].x)) \(num(p[1].y))")
            case .addCurveToPoint:
                parts.append("C\(num(p[0].x)) \(num(p[0].y)) \(num(p[1].x)) \(num(p[1].y)) \(num(p[2].x)) \(num(p[2].y))")
            case .closeSubpath:
                parts.append("Z")
            @unknown default:
                break
            }
        }
        return parts.joined()
    }

    /// Nombre compact avec point décimal, quelle que soit la langue de l'appareil.
    private func num(_ value: CGFloat) -> String {
        let rounded = (value * 1000).rounded() / 1000
        if rounded == rounded.rounded() { return String(Int(rounded)) }
        return String(format: "%.3f", Double(rounded))
            .replacingOccurrences(of: #"0+$"#, with: "", options: .regularExpression)
    }

    private func num(_ value: Double) -> String { num(CGFloat(value)) }

    private func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
