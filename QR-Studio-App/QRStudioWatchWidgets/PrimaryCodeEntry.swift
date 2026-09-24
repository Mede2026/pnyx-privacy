import OSLog
import QRCore
import SwiftData
import SwiftUI
import WidgetKit

struct PrimaryCodeEntry: TimelineEntry {
    let date: Date
    let title: String?
    /// Petit QR rendu sur la montre (PNG), pour la complication rectangulaire.
    let image: Data?
}
