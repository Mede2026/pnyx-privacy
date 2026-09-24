#if !os(watchOS)
import CoreGraphics
import CoreText
import Foundation
import OSLog

/// Planche PDF multipage : une grille de codes avec leurs légendes.
public enum PDFSheetExporter {
    public struct Item: Sendable {
        public var request: RenderRequest
        public var title: String
        public var subtitle: String

        public init(request: RenderRequest, title: String, subtitle: String) {
            self.request = request
            self.title = title
            self.subtitle = subtitle
        }
    }

    /// Format Lettre pour les régions en mesures impériales, A4 ailleurs (en points).
    public static var defaultPageSize: CGSize {
        Locale.current.measurementSystem == .us ? CGSize(width: 612, height: 792) : CGSize(width: 595, height: 842)
    }

    public static func pdf(_ items: [Item], pageSize: CGSize = defaultPageSize, columns: Int = 3, rows: Int = 4) async throws -> Data {
        var drawings: [(CodeDrawing?, Item)] = []
        for item in items {
            // Un code impossible à dessiner garde sa place avec sa légende, sans bloquer la planche.
            do {
                drawings.append((try await CodeRenderer.shared.drawing(for: item.request), item))
            } catch {
                Logger.export.error("Code non dessiné dans la planche : \(error.localizedDescription)")
                drawings.append((nil, item))
            }
        }

        let data = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw RenderError.contextCreationFailed
        }
        let margin: CGFloat = 36
        let cellWidth = (pageSize.width - margin * 2) / CGFloat(columns)
        let cellHeight = (pageSize.height - margin * 2) / CGFloat(rows)
        let perPage = columns * rows

        for pageStart in stride(from: 0, to: max(drawings.count, 1), by: perPage) {
            context.beginPDFPage(nil)
            for (offset, element) in drawings[pageStart..<min(pageStart + perPage, drawings.count)].enumerated() {
                let column = offset % columns
                let row = offset / columns
                // Origine PDF en bas à gauche : la première rangée est en haut de la page.
                let cell = CGRect(x: margin + CGFloat(column) * cellWidth,
                                  y: pageSize.height - margin - CGFloat(row + 1) * cellHeight,
                                  width: cellWidth, height: cellHeight)
                draw(element.0, element.1, in: cell.insetBy(dx: 8, dy: 8), context: context)
            }
            context.endPDFPage()
        }
        context.closePDF()
        return data as Data
    }

    private static func draw(_ drawing: CodeDrawing?, _ item: Item, in cell: CGRect, context: CGContext) {
        let captionHeight: CGFloat = 30
        let codeArea = CGRect(x: cell.minX, y: cell.minY + captionHeight, width: cell.width, height: cell.height - captionHeight)
        if let drawing {
            let scale = min(codeArea.width / drawing.size.width, codeArea.height / drawing.size.height)
            let size = CGSize(width: drawing.size.width * scale, height: drawing.size.height * scale)
            context.saveGState()
            context.translateBy(x: codeArea.midX - size.width / 2, y: codeArea.maxY - size.height)
            drawing.draw(in: context, scale: scale)
            context.restoreGState()
        }
        text(item.title, bold: true, size: 9, in: CGRect(x: cell.minX, y: cell.minY + 15, width: cell.width, height: 13), context: context)
        text(item.subtitle, bold: false, size: 7, in: CGRect(x: cell.minX, y: cell.minY + 2, width: cell.width, height: 12), context: context)
    }

    private static func text(_ string: String, bold: Bool, size: CGFloat, in rect: CGRect, context: CGContext) {
        let font = CodeDrawing.font(size: size, bold: bold)
        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0.1, alpha: 1)
        ]
        let full = CTLineCreateWithAttributedString(NSAttributedString(string: string, attributes: attributes))
        let ellipsis = CTLineCreateWithAttributedString(NSAttributedString(string: "…", attributes: attributes))
        let line = CTLineCreateTruncatedLine(full, Double(rect.width), .middle, ellipsis) ?? full
        let width = CTLineGetTypographicBounds(line, nil, nil, nil)
        context.textPosition = CGPoint(x: rect.midX - CGFloat(width) / 2, y: rect.minY + 2)
        CTLineDraw(line, context)
    }
}
#endif
