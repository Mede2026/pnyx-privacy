import QRCore
import SwiftUI

struct CircleControl: View {
    let systemImage: String
    var tint: Color?
    let label: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint ?? .primary)
                .frame(width: 52, height: 52)
                .contentShape(Circle())
                .glassCircleButton()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}
