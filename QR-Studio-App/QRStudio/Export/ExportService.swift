import Foundation
import OSLog
import Photos
import QRCore
import UIKit

/// Écriture des fichiers partagés (dossier temporaire) et enregistrement dans Photos.
enum ExportService {
    static let sizes = [512, 1024, 2048]

    /// Fichier prêt à partager, rendu hors du fil principal.
    static func file(for request: RenderRequest, format: ExportFormat, size: Int, name: String) async throws -> URL {
        let drawing = try await CodeRenderer.shared.drawing(for: request)
        let data = try await Task.detached(priority: .userInitiated) { () throws -> Data in
            switch format {
            case .png: try drawing.pngData(width: size)
            case .jpeg: try drawing.jpegData(width: size)
            case .pdf: try drawing.pdfData(width: CGFloat(size) / 2)
            case .svg: Data(drawing.svgString(pixelWidth: size).utf8)
            }
        }.value
        return try write(data, name: name, fileExtension: format.fileExtension)
    }

    static func write(_ data: Data, name: String, fileExtension: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Exports", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(safeFileName(name)).appendingPathExtension(fileExtension)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func safeFileName(_ name: String) -> String {
        let cleaned = name.components(separatedBy: CharacterSet(charactersIn: "/\\:?%*|\"<>\n\r")).joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? "QR Studio" : String(cleaned.prefix(60))
    }

    /// Enregistre dans Photos avec une autorisation en ajout seulement.
    static func saveToPhotos(_ request: RenderRequest, size: Int) async throws {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { throw ExportError.photosDenied }
        let drawing = try await CodeRenderer.shared.drawing(for: request)
        let png = try drawing.pngData(width: size)
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetCreationRequest.forAsset().addResource(with: .photo, data: png, options: nil)
        }
    }

    static func print(_ request: RenderRequest, name: String) async throws {
        let drawing = try await CodeRenderer.shared.drawing(for: request)
        let pdf = try drawing.pdfData(width: 360)
        let controller = UIPrintInteractionController.shared
        let info = UIPrintInfo.printInfo()
        info.jobName = name
        info.outputType = .grayscale
        controller.printInfo = info
        controller.printingItem = pdf
        controller.present(animated: true)
    }

    // MARK: - Historique

    static func csvFile(for entries: [CodeEntry], name: String) throws -> URL {
        try write(CSVExporter.csv(entries.map(ExportRow.init)), name: name, fileExtension: "csv")
    }

    /// JSON au format de sauvegarde : réimportable avec « Fusionner ».
    static func jsonFile(for entries: [CodeEntry], name: String) throws -> URL {
        try write(BackupCodec.export(entries: entries), name: name, fileExtension: "json")
    }

    static func pdfSheet(for entries: [CodeEntry], name: String) async throws -> URL {
        let items = entries.map { entry in
            PDFSheetExporter.Item(request: entry.previewRequest, title: entry.displayTitle,
                                  subtitle: String(entry.summary.prefix(60)))
        }
        return try write(try await PDFSheetExporter.pdf(items), name: name, fileExtension: "pdf")
    }

    enum ExportError: LocalizedError {
        case photosDenied

        var errorDescription: String? {
            String(localized: "QR Studio n’est pas autorisé à ajouter à Photos. Vous pouvez l’autoriser dans Réglages.")
        }
    }
}
