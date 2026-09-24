import QRCore
import SwiftUI

struct ZoomSelector: View {
    @Environment(ScannerModel.self) private var model
    let zoomRange: ClosedRange<Double>

    var body: some View {
        HStack(spacing: 2) {
            ForEach([1.0, 2.0], id: \.self) { factor in
                Button {
                    model.zoomFactor = factor
                } label: {
                    Text(factor == 1 ? "1×" : "2×")
                        .font(.footnote.weight(.bold))
                        .frame(width: 36, height: 36)
                        .foregroundStyle(abs(model.zoomFactor - factor) < 0.05 ? Color.yellow : Color.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(factor == 1 ? Text("Zoom 1×") : Text("Zoom 2×"))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .glassRoundedRect(cornerRadius: 26, interactive: true)
    }
}
