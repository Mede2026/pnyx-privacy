import OSLog
import QRCore
import SwiftData
import SwiftUI
import WidgetKit

/// Affiche le code principal (carte de fidélité, laissez-passer) : un toucher l'ouvre en grand.
struct MainCodeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "MainCode", provider: MainCodeProvider()) { entry in
            MainCodeWidgetView(entry: entry)
                .containerBackground(.background, for: .widget)
                .widgetURL(entry.id.map { URL(string: "qrstudio://code/\($0.uuidString)") } ?? URL(string: "qrstudio://create"))
        }
        .configurationDisplayName("Code principal")
        .description("Le code que vous montrez le plus souvent, toujours à portée de main.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
