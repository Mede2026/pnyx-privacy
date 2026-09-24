import QRCore
import SwiftUI
import UIKit

/// Rendu des codes sur la montre elle-même (pas d'image transférée depuis l'iPhone).
/// Core Image n'existe pas sur watchOS : QRCore utilise alors ses encodeurs QR et Code 128 en Swift pur.
enum WatchCodeImage {
    static func render(_ request: RenderRequest, width: Int) async throws -> UIImage {
        let drawing = try await CodeRenderer.shared.drawing(for: request)
        guard let image = UIImage(data: try drawing.pngData(width: width)) else {
            throw RenderError.contextCreationFailed
        }
        return image
    }
}
