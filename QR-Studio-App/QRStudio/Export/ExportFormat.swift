import Foundation
import OSLog
import Photos
import QRCore
import UIKit

/// Formats d'export d'un code.
enum ExportFormat: String, CaseIterable, Identifiable {
    case png, jpeg, pdf, svg
    var id: String { rawValue }
    var title: String { rawValue.uppercased() }
    var fileExtension: String { rawValue == "jpeg" ? "jpg" : rawValue }
}
