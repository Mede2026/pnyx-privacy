import OSLog
import QRCore
import SwiftData
import SwiftUI
import WidgetKit

struct PrimaryCodeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PrimaryCode", provider: PrimaryCodeProvider()) { entry in
            PrimaryCodeWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
                .widgetURL(URL(string: "qrstudio://primary"))
        }
        .configurationDisplayName("Code principal")
        .description("Ouvre votre code principal, par exemple une carte de fidélité.")
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryCorner, .accessoryInline])
    }
}
