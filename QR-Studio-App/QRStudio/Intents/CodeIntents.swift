import AppIntents
import Foundation
import QRCore
import SwiftUI

/// Ouvre l'app directement sur le scanner.
struct ScanCodeIntent: AppIntent {
    static let title: LocalizedStringResource = "Scanner un code"
    static let description = IntentDescription("Ouvre QR Studio directement sur le scanner.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        AppServices.shared.router.openScanner()
        return .result()
    }
}
