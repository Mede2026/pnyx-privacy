import PhotosUI
import QRCore
import SwiftUI
import UIKit

/// Scan depuis une image : photothèque ou presse-papier. Le décodage Vision tourne hors du fil principal.
enum ImageBarcodeDetector {
    enum DetectionError: LocalizedError {
        case unreadable
        case noCode

        var errorDescription: String? {
            switch self {
            case .unreadable: String(localized: "Cette image n’a pas pu être ouverte.")
            case .noCode: String(localized: "Aucun code n’a été trouvé dans cette image.")
            }
        }
    }

    static func detect(in item: PhotosPickerItem) async throws -> [DetectedBarcode] {
        guard let data = try await item.loadTransferable(type: Data.self) else { throw DetectionError.unreadable }
        return try await detect(imageData: data)
    }

    static func detect(in image: UIImage) async throws -> [DetectedBarcode] {
        guard let data = image.pngData() else { throw DetectionError.unreadable }
        return try await detect(imageData: data)
    }

    static func detect(imageData: Data) async throws -> [DetectedBarcode] {
        let codes = try await Task.detached(priority: .userInitiated) {
            try ImageBarcodeDecoder.decode(imageData: imageData)
        }.value
        guard !codes.isEmpty else { throw DetectionError.noCode }
        return codes
    }
}
