import OSLog
import QRCore
import SwiftData
import SwiftUI
import WidgetKit

/// Ouvre directement le scanner.
struct ScanWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "Scan", provider: StaticProvider()) { _ in
            ScanWidgetView()
                .containerBackground(Color.accentColor.gradient, for: .widget)
                .widgetURL(URL(string: "qrstudio://scan"))
        }
        .configurationDisplayName("Scanner")
        .description("Ouvre QR Studio directement sur le scanner.")
        .supportedFamilies([.systemSmall, .accessoryCircular])
    }
}
