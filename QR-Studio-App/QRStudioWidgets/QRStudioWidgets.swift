import OSLog
import QRCore
import SwiftData
import SwiftUI
import WidgetKit

/// Widgets de l'écran d'accueil et de l'écran verrouillé.
@main
struct QRStudioWidgets: WidgetBundle {
    var body: some Widget {
        ScanWidget()
        MainCodeWidget()
    }
}
