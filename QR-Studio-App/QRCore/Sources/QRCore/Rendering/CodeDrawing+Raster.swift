import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

public enum RenderError: Error, Sendable, Equatable {
    case contextCreationFailed
    case encodingFailed
    case capacityExceeded(symbology: Symbology)
    case invalidContent(String)
    case unsupportedOnPlatform(Symbology)
}

extension RenderError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .contextCreationFailed, .encodingFailed:
            L("L’image n’a pas pu être créée.")
        case .capacityExceeded(.qr), .capacityExceeded(.pdf417):
            L("Ce contenu dépasse la capacité maximale d’un code. Raccourcissez-le, par exemple avec un lien vers le texte complet.")
        case .capacityExceeded(let symbology):
            String(format: L("Ce contenu est trop long pour %@. Essayez QR ou PDF417."), symbology.displayName)
        case .invalidContent(let message):
            message
        case .unsupportedOnPlatform(let symbology):
            String(format: L("%@ ne peut pas être dessiné sur cet appareil."), symbology.displayName)
        }
    }
}

public extension CodeDrawing {
    /// Dessine dans un contexte dont l'origine est en bas à gauche (convention Core Graphics).
    func draw(in context: CGContext, scale: CGFloat) {
        context.saveGState()
        context.translateBy(x: 0, y: size.height * scale)
        context.scaleBy(x: scale, y: -scale)
        context.setShouldAntialias(true)

        if let background {
            context.setFillColor(background.cgColor)
            let rect = CGRect(origin: .zero, size: size)
            if backgroundCornerRadius > 0 {
                context.addPath(CGPath(roundedRect: rect, cornerWidth: backgroundCornerRadius,
                                       cornerHeight: backgroundCornerRadius, transform: nil))
                context.fillPath()
            } else {
                context.fill(rect)
            }
        }

        for layer in layers {
            fill(layer, in: context)
        }

        for item in images {
            guard let image = Self.decodePNG(item.pngData) else { continue }
            context.saveGState()
            context.translateBy(x: item.rect.minX, y: item.rect.maxY)
            context.scaleBy(x: 1, y: -1)
            context.interpolationQuality = .high
            context.draw(image, in: CGRect(origin: .zero, size: item.rect.size))
            context.restoreGState()
        }

        for text in texts {
            draw(text, in: context)
        }
        context.restoreGState()
    }

    /// Image bitmap de la largeur demandée, en pixels.
    func makeImage(width: Int) throws -> CGImage {
        let pixels = pixelSize(forWidth: width)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let context = CGContext(
                data: nil,
                width: pixels.width,
                height: pixels.height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else {
            throw RenderError.contextCreationFailed
        }
        draw(in: context, scale: CGFloat(pixels.width) / size.width)
        guard let image = context.makeImage() else { throw RenderError.contextCreationFailed }
        return image
    }

    func pngData(width: Int) throws -> Data {
        try Self.encode(makeImage(width: width), type: .png)
    }

    func jpegData(width: Int, quality: Double = 0.92) throws -> Data {
        // JPEG n'a pas de transparence : on compose sur blanc.
        var opaque = self
        if opaque.background == nil { opaque.background = .white }
        return try Self.encode(opaque.makeImage(width: width), type: .jpeg, quality: quality)
    }

    #if !os(watchOS)
    /// PDF vectoriel d'une page, dimensionné en points à la largeur demandée.
    func pdfData(width: CGFloat = 512) throws -> Data {
        let data = NSMutableData()
        let height = width / aspectRatio
        var mediaBox = CGRect(x: 0, y: 0, width: width, height: height)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw RenderError.contextCreationFailed
        }
        context.beginPDFPage(nil)
        draw(in: context, scale: width / size.width)
        context.endPDFPage()
        context.closePDF()
        return data as Data
    }
    #endif

    static func encode(_ image: CGImage, type: UTType, quality: Double = 1) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data as CFMutableData, type.identifier as CFString, 1, nil
        ) else { throw RenderError.encodingFailed }
        let options = [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary
        CGImageDestinationAddImage(destination, image, options)
        guard CGImageDestinationFinalize(destination) else { throw RenderError.encodingFailed }
        return data as Data
    }

    static func decodePNG(_ data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }

    private func fill(_ layer: Layer, in context: CGContext) {
        let rule: CGPathFillRule = layer.evenOdd ? .evenOdd : .winding
        switch layer.fill {
        case .solid(let color):
            context.setFillColor(color.cgColor)
            context.addPath(layer.path)
            context.fillPath(using: rule)
        case .linear(let from, let to, let start, let end):
            guard let gradient = Self.gradient(from, to) else { return }
            context.saveGState()
            context.addPath(layer.path)
            context.clip(using: rule)
            context.drawLinearGradient(gradient, start: start, end: end,
                                       options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])
            context.restoreGState()
        case .radial(let from, let to, let center, let radius):
            guard let gradient = Self.gradient(from, to) else { return }
            context.saveGState()
            context.addPath(layer.path)
            context.clip(using: rule)
            context.drawRadialGradient(gradient, startCenter: center, startRadius: 0,
                                       endCenter: center, endRadius: radius,
                                       options: [.drawsAfterEndLocation])
            context.restoreGState()
        }
    }

    private static func gradient(_ from: RGBAColor, _ to: RGBAColor) -> CGGradient? {
        CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
                   colors: [from.cgColor, to.cgColor] as CFArray,
                   locations: [0, 1])
    }

    private func draw(_ item: TextItem, in context: CGContext) {
        let font = CodeDrawing.font(size: item.fontSize, bold: item.bold)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): item.color.cgColor
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: item.text, attributes: attributes))
        let width = CTLineGetTypographicBounds(line, nil, nil, nil)
        context.saveGState()
        context.translateBy(x: item.center.x - CGFloat(width) / 2, y: item.center.y)
        context.scaleBy(x: 1, y: -1)
        context.textPosition = .zero
        CTLineDraw(line, context)
        context.restoreGState()
    }

    static func font(size: CGFloat, bold: Bool) -> CTFont {
        let base = CTFontCreateUIFontForLanguage(bold ? .emphasizedSystem : .system, size, nil)
            ?? CTFontCreateWithName("Helvetica" as CFString, size, nil)
        // Chiffres à chasse fixe, pour aligner les chiffres sous les barres.
        let feature: [CFString: Any] = [
            kCTFontFeatureTypeIdentifierKey: kNumberSpacingType,
            kCTFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector
        ]
        let descriptor = CTFontDescriptorCreateWithAttributes(
            [kCTFontFeatureSettingsAttribute: [feature]] as CFDictionary
        )
        return CTFontCreateCopyWithAttributes(base, size, nil, descriptor)
    }

    /// Largeur d'un texte en unités de dessin, pour ajuster une légende trop longue.
    static func textWidth(_ text: String, fontSize: CGFloat, bold: Bool) -> CGFloat {
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font(size: fontSize, bold: bold)
        ]
        let line = CTLineCreateWithAttributedString(NSAttributedString(string: text, attributes: attributes))
        return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
    }
}
