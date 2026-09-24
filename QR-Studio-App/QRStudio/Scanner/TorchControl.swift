import QRCore
import SwiftUI

/// Bouton torche. Allumé, il s'étend en groupe de commandes d'intensité (morphing Liquid Glass).
/// Il doit vivre dans le GlassGroup des commandes du scanner.
struct TorchControl: View {
    @Environment(ScannerModel.self) private var model
    @Namespace private var glass

    private static let levels: [(value: Float, symbol: String, label: LocalizedStringKey)] = [
        (0.25, "sun.min", "Lampe faible"),
        (0.6, "sun.max", "Lampe moyenne"),
        (1, "sun.max.fill", "Lampe forte")
    ]

    var body: some View {
        HStack(spacing: 8) {
            morphing(id: "torch") {
                CircleControl(
                    systemImage: model.isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill",
                    tint: model.isTorchOn ? .yellow : nil,
                    label: model.isTorchOn ? "Éteindre la lampe" : "Allumer la lampe"
                ) {
                    withAnimation(.bouncy) { model.isTorchOn.toggle() }
                    TorchController.set(model.isTorchOn, level: model.torchLevel)
                }
            }
            if model.isTorchOn {
                ForEach(Self.levels, id: \.value) { level in
                    morphing(id: "level-\(level.value)") {
                        Button {
                            model.torchLevel = level.value
                            TorchController.set(true, level: level.value)
                        } label: {
                            Image(systemName: level.symbol)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(model.torchLevel == level.value ? .yellow : .primary)
                                .frame(width: 40, height: 40)
                                .contentShape(Circle())
                                .glassCircleButton()
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(level.label)
                        .accessibilityAddTraits(model.torchLevel == level.value ? .isSelected : [])
                    }
                }
            }
        }
    }

    /// Identifiant de morphing sur iOS 26 ; simple transition avant.
    @ViewBuilder
    private func morphing(id: String, @ViewBuilder content: () -> some View) -> some View {
        if #available(iOS 26.0, *) {
            content().glassEffectID(id, in: glass)
        } else {
            content().transition(.scale.combined(with: .opacity))
        }
    }
}
