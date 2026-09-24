import QRCore
import SwiftUI
#if canImport(UIKit)
import UIKit
#else
import AppKit
#endif

/// Préparation des logos : PNG de 512 px de côté au plus, pour garder la base légère.
enum LogoImage {
    static func png(from image: PlatformImage, maxSide: CGFloat = 512) -> Data? {
        let scale = min(1, maxSide / max(image.size.width, image.size.height))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        #if canImport(UIKit)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).pngData { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        #else
        guard let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
                                            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                            colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        image.draw(in: CGRect(origin: .zero, size: size))
        NSGraphicsContext.restoreGraphicsState()
        return bitmap.representation(using: .png, properties: [:])
        #endif
    }

    static func png(symbol: String, color: RGBAColor) -> Data? {
        #if canImport(UIKit)
        let configuration = UIImage.SymbolConfiguration(pointSize: 200, weight: .semibold)
        guard let image = UIImage(systemName: symbol, withConfiguration: configuration)?
            .withTintColor(UIColor(color.color), renderingMode: .alwaysOriginal) else { return nil }
        return png(from: image)
        #else
        let configuration = NSImage.SymbolConfiguration(pointSize: 200, weight: .semibold)
            .applying(NSImage.SymbolConfiguration(paletteColors: [NSColor(color.color)]))
        guard let image = NSImage(systemSymbolName: symbol, accessibilityDescription: nil)?
            .withSymbolConfiguration(configuration) else { return nil }
        return png(from: image)
        #endif
    }
}
