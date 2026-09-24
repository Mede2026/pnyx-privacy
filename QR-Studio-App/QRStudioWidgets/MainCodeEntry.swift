import OSLog
import QRCore
import SwiftData
import SwiftUI
import WidgetKit

struct MainCodeEntry: TimelineEntry {
    let date: Date
    let id: UUID?
    let title: String?
    let image: Data?
}
