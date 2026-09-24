import OSLog
import QRCore
import SwiftData
import SwiftUI
import WidgetKit

struct ScanWidgetView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if family == .accessoryCircular {
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "qrcode.viewfinder").font(.title2)
            }
            .accessibilityLabel(Text("Scanner un code"))
        } else {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 40, weight: .semibold))
                Spacer()
                Text("Scanner")
                    .font(.headline)
                Text("QR et codes-barres")
                    .font(.caption)
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
