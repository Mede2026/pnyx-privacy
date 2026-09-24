import OSLog
import QRCore
import SwiftData
import SwiftUI
import WidgetKit

/// Complication et widget Smart Stack : ouvrent directement le code marqué comme principal.
@main
struct QRStudioWatchWidgets: WidgetBundle {
    var body: some Widget {
        PrimaryCodeWidget()
    }
}
