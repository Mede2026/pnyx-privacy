import CoreTransferable
import Foundation
import os
import QRCore
import UniformTypeIdentifiers

/// Code glissé vers le Finder ou une autre app, ou partagé : une image PNG, rendue au moment voulu.
struct DraggableCode: Transferable {
    let request: RenderRequest
    let name: String

    @MainActor
    init(entry: CodeEntry) {
        request = entry.previewRequest
        name = entry.displayTitle
    }

    init(request: RenderRequest, name: String) {
        self.request = request
        self.name = name
    }

    private static let lastExport = OSAllocatedUnfairLock<Date>(initialState: .distantPast)

    /// Vrai juste après un rendu pour un glisser : permet d'ignorer un dépôt sur la fenêtre d'origine.
    static var wasJustExported: Bool {
        Date.now.timeIntervalSince(lastExport.withLock { $0 }) < 3
    }

    private static func markExported() {
        lastExport.withLock { $0 = .now }
    }

    nonisolated static func fileName(_ name: String) -> String {
        let safe = name.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>")).joined(separator: "-")
        return safe.isEmpty ? "QR Studio" : String(safe.prefix(80))
    }

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .png) { code in
            markExported()
            let drawing = try await CodeRenderer.shared.drawing(for: code.request)
            let data = try drawing.pngData(width: 1024)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(Self.fileName(code.name)).appendingPathExtension("png")
            try data.write(to: url, options: .atomic)
            return SentTransferredFile(url)
        }
        DataRepresentation(exportedContentType: .png) { code in
            markExported()
            return try await CodeRenderer.shared.drawing(for: code.request).pngData(width: 1024)
        }
    }
}
