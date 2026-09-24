import QRCore
import SwiftUI
import UniformTypeIdentifiers

/// Formats d'export et écriture des données.
enum MacExport {
    enum Format: String, CaseIterable, Identifiable {
        case png, jpeg, pdf, svg
        var id: String { rawValue }
        var title: String { rawValue.uppercased() }

        var contentType: UTType {
            switch self {
            case .png: .png
            case .jpeg: .jpeg
            case .pdf: .pdf
            case .svg: .svg
            }
        }
    }

    static let sizes = [512, 1024, 2048]

    static func data(for request: RenderRequest, format: Format, size: Int) async throws -> Data {
        let drawing = try await CodeRenderer.shared.drawing(for: request)
        switch format {
        case .png: return try drawing.pngData(width: size)
        case .jpeg: return try drawing.jpegData(width: size)
        case .pdf: return try drawing.pdfData(width: CGFloat(size) / 2)
        case .svg: return Data(drawing.svgString(pixelWidth: size).utf8)
        }
    }

    nonisolated static func safeFileName(_ name: String) -> String {
        let cleaned = name.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>\n\r")).joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "QR Studio" : String(cleaned.prefix(60))
    }
}
