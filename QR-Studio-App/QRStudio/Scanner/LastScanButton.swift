import QRCore
import SwiftUI

/// Vignette du dernier code scanné ; la toucher rouvre sa feuille.
struct LastScanButton: View {
    @Environment(ScannerModel.self) private var model

    var body: some View {
        if let entry = model.lastEntry, entry.deletedAt == nil {
            Button {
                model.reopenLast()
            } label: {
                CodeThumbnail(entry: entry, size: 48)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Dernier scan : \(entry.displayTitle)"))
        }
    }
}
