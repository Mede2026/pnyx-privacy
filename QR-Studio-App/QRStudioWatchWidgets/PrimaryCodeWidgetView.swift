import OSLog
import QRCore
import SwiftData
import SwiftUI
import WidgetKit

struct PrimaryCodeWidgetView: View {
    let entry: PrimaryCodeEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryRectangular:
            HStack(spacing: 6) {
                if let data = entry.image, let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Image(systemName: "qrcode").font(.title2)
                }
                VStack(alignment: .leading) {
                    Text("QR Studio").font(.caption2).foregroundStyle(.secondary)
                    Text(entry.title ?? String(localized: "Aucun code principal"))
                        .font(.headline)
                        .lineLimit(2)
                }
            }
        case .accessoryInline:
            Label(entry.title ?? String(localized: "QR Studio"), systemImage: "qrcode")
        default:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "qrcode").font(.title3)
            }
            .widgetLabel(entry.title ?? "QR Studio")
        }
    }
}
