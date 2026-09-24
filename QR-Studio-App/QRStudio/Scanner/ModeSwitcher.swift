import QRCore
import SwiftUI

/// Sélecteur Simple | Lot, toujours visible : impossible d'oublier le mode actif.
struct ModeSwitcher: View {
    @Environment(ScannerModel.self) private var model
    @Namespace private var namespace

    var body: some View {
        HStack(spacing: 4) {
            segment(.single, title: "Simple")
            segment(.batch, title: model.mode == .batch && !model.batch.isEmpty ? "Lot · \(model.batch.count)" : "Lot")
        }
        .padding(4)
        .glassCapsule()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Mode de scan")
    }

    private func segment(_ mode: ScanMode, title: LocalizedStringKey) -> some View {
        Button {
            model.mode = mode
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .foregroundStyle(model.mode == mode ? Color.white : Color.primary)
                .background {
                    if model.mode == mode {
                        Capsule().fill(Color.accentColor).matchedGeometryEffect(id: "segment", in: namespace)
                    }
                }
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(model.mode == mode ? .isSelected : [])
    }
}
