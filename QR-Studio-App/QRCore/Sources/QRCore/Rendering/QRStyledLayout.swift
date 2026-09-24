import CoreGraphics
import Foundation

/// Redessine une matrice QR module par module, selon le style.
enum QRStyledLayout {
    static func drawing(matrix: BitMatrix, style: StyleConfig) -> CodeDrawing {
        let n = matrix.width
        let quiet = CGFloat(style.effectiveQuietZone)
        let codeSide = CGFloat(n) + quiet * 2

        let hasFrame = style.frameEnabled
        let border: CGFloat = hasFrame ? max(1, (codeSide * 0.04).rounded()) : 0
        let caption = style.caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let captionHeight: CGFloat = hasFrame && !caption.isEmpty ? codeSide * 0.2 : 0
        let canvas = CGSize(width: codeSide + border * 2, height: codeSide + border * 2 + captionHeight)

        var drawing = CodeDrawing(size: canvas, background: style.background)
        if hasFrame { drawing.backgroundCornerRadius = border * 2.5 }

        let origin = CGPoint(x: border + quiet, y: border + quiet)
        let symbolRect = CGRect(origin: origin, size: CGSize(width: n, height: n))

        // Zone réservée au logo : les modules qui la touchent ne sont pas dessinés.
        var logoRect: CGRect?
        if style.hasLogo {
            let side = (CGFloat(n) * style.effectiveLogoScale).rounded()
            logoRect = CGRect(x: symbolRect.midX - side / 2, y: symbolRect.midY - side / 2, width: side, height: side)
        }
        let clearRect = logoRect?.insetBy(dx: -0.5, dy: -0.5)

        func isFinder(_ x: Int, _ y: Int) -> Bool {
            (x < 7 && y < 7) || (x >= n - 7 && y < 7) || (x < 7 && y >= n - 7)
        }
        func isCleared(_ x: Int, _ y: Int) -> Bool {
            guard let clearRect else { return false }
            let module = CGRect(x: origin.x + CGFloat(x), y: origin.y + CGFloat(y), width: 1, height: 1)
            return clearRect.intersects(module)
        }
        func isDataModule(_ x: Int, _ y: Int) -> Bool {
            matrix[x, y] && !isFinder(x, y) && !isCleared(x, y)
        }

        let dataPath = CGMutablePath()
        for y in 0..<n {
            for x in 0..<n where isDataModule(x, y) {
                ShapeGeometry.addModule(style.moduleShape, to: dataPath, x: x, y: y) { dx, dy in
                    isDataModule(x + dx, y + dy)
                }
            }
        }
        let placed = CGAffineTransform(translationX: origin.x, y: origin.y)
        let dataFill = fill(for: style, in: symbolRect)
        drawing.layers.append(.init(path: dataPath.copy(using: [placed]) ?? dataPath, fill: dataFill, evenOdd: false))

        // Les trois yeux : structure 7 × 7 conservée quelle que soit la forme.
        let eyeOrigins = [CGPoint(x: 0, y: 0), CGPoint(x: n - 7, y: 0), CGPoint(x: 0, y: n - 7)]
        let framePath = CGMutablePath()
        let ballPath = CGMutablePath()
        for eye in eyeOrigins {
            let point = CGPoint(x: origin.x + eye.x, y: origin.y + eye.y)
            ShapeGeometry.addEyeFrame(style.eyeFrameShape, to: framePath, origin: point)
            ShapeGeometry.addEyeBall(style.eyeBallShape, to: ballPath, origin: point)
        }
        let frameFill = style.eyeFrameColor.map(CodeDrawing.Fill.solid) ?? dataFill
        let ballFill = style.eyeBallColor.map(CodeDrawing.Fill.solid) ?? frameFill
        drawing.layers.append(.init(path: framePath, fill: frameFill, evenOdd: true))
        drawing.layers.append(.init(path: ballPath, fill: ballFill, evenOdd: false))

        // Logo sur fond blanc arrondi.
        if let logoRect, let logo = style.logoPNG {
            let backdrop = logoRect.insetBy(dx: -0.4, dy: -0.4)
            let radius = backdrop.width * 0.2
            drawing.layers.append(.init(
                path: CGPath(roundedRect: backdrop, cornerWidth: radius, cornerHeight: radius, transform: nil),
                fill: .solid(.white),
                evenOdd: false
            ))
            drawing.images.append(.init(pngData: logo, rect: fitted(logo, in: logoRect.insetBy(dx: 0.3, dy: 0.3))))
        }

        if hasFrame {
            addFrame(to: &drawing, style: style, border: border, codeSide: codeSide,
                     caption: caption, captionHeight: captionHeight)
        }
        return drawing
    }

    private static func fill(for style: StyleConfig, in rect: CGRect) -> CodeDrawing.Fill {
        guard let end = style.gradientEnd else { return .solid(style.foreground) }
        switch style.gradientKind {
        case .none:
            return .solid(style.foreground)
        case .linear:
            return .linear(style.foreground, end,
                           start: CGPoint(x: rect.minX, y: rect.minY),
                           end: CGPoint(x: rect.maxX, y: rect.maxY))
        case .radial:
            return .radial(style.foreground, end,
                           center: CGPoint(x: rect.midX, y: rect.midY),
                           radius: rect.width / 2 * 1.2)
        }
    }

    private static func addFrame(
        to drawing: inout CodeDrawing,
        style: StyleConfig,
        border: CGFloat,
        codeSide: CGFloat,
        caption: String,
        captionHeight: CGFloat
    ) {
        let color = style.frameColor ?? style.foreground
        let outer = CGRect(origin: .zero, size: drawing.size)
        let hole = CGRect(x: border, y: border, width: codeSide, height: codeSide)
        let path = CGMutablePath()
        path.addRoundedRect(in: outer, cornerWidth: border * 2.5, cornerHeight: border * 2.5)
        path.addRoundedRect(in: hole, cornerWidth: border * 1.5, cornerHeight: border * 1.5)
        drawing.layers.append(.init(path: path, fill: .solid(color), evenOdd: true))

        guard !caption.isEmpty else { return }
        let maxWidth = codeSide * 0.9
        var fontSize = captionHeight * 0.5
        let measured = CodeDrawing.textWidth(caption, fontSize: fontSize, bold: true)
        if measured > maxWidth { fontSize *= maxWidth / measured }
        let baseline = border + codeSide + captionHeight / 2 + fontSize * 0.35
        drawing.texts.append(.init(
            text: caption,
            center: CGPoint(x: drawing.size.width / 2, y: baseline),
            fontSize: fontSize,
            color: style.background ?? .white,
            bold: true
        ))
    }

    /// Rectangle ajusté aux proportions de l'image, centré dans `box`.
    private static func fitted(_ png: Data, in box: CGRect) -> CGRect {
        guard let image = CodeDrawing.decodePNG(png), image.width > 0, image.height > 0 else { return box }
        let ratio = CGFloat(image.width) / CGFloat(image.height)
        if ratio > 1 {
            let height = box.width / ratio
            return CGRect(x: box.minX, y: box.midY - height / 2, width: box.width, height: height)
        }
        let width = box.height * ratio
        return CGRect(x: box.midX - width / 2, y: box.minY, width: width, height: box.height)
    }
}
