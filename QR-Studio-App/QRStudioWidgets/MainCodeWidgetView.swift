import OSLog
import QRCore
import SwiftData
import SwiftUI
import WidgetKit

struct MainCodeWidgetView: View {
    let entry: MainCodeEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let data = entry.image, let image = UIImage(data: data) {
            switch family {
            case .systemMedium, .accessoryRectangular:
                HStack(spacing: 12) {
                    code(image)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Code principal").font(.caption).foregroundStyle(.secondary)
                        Text(entry.title ?? "").font(.headline).lineLimit(3)
                    }
                    Spacer(minLength: 0)
                }
            default:
                code(image)
            }
        } else {
            VStack(spacing: 6) {
                Image(systemName: "star.square").font(.title)
                Text("Marquez un code comme principal ou favori dans QR Studio.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func code(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .interpolation(.none)
            .resizable()
            .scaledToFit()
            .padding(4)
            .background(Color.white, in: RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(Text(entry.title ?? "Code"))
    }
}
