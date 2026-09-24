import SwiftUI

/// Liquid Glass natif sur iOS 26 et plus, avec repli système sur iOS 17 et 18.
/// Jamais d'imitation maison à base de flou : on utilise les API d'Apple ou un fond opaque.
private struct GlassShapeModifier<S: Shape>: ViewModifier {
    let shape: S
    let interactive: Bool
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        if reduceTransparency {
            content.background(Color.secondaryBackground, in: shape)
        } else if #available(iOS 26.0, macOS 26.0, *) {
            // .glassEffect s'applique après les modificateurs de disposition et d'apparence.
            content.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            content.background(.regularMaterial, in: shape)
        }
    }
}

extension View {
    /// Badge ou groupe en verre, en lecture seule (pas de réaction au toucher).
    func glassCapsule() -> some View {
        modifier(GlassShapeModifier(shape: Capsule(), interactive: false))
    }

    /// Bouton rond en verre, qui réagit au toucher.
    func glassCircleButton() -> some View {
        modifier(GlassShapeModifier(shape: Circle(), interactive: true))
    }

    func glassRoundedRect(cornerRadius: CGFloat = 20, interactive: Bool = false) -> some View {
        modifier(GlassShapeModifier(shape: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous),
                                    interactive: interactive))
    }

    /// Style de bouton des feuilles : .glass / .glassProminent, repli .bordered sur iOS 17 et 18.
    @ViewBuilder
    func glassButtonStyle(prominent: Bool = false) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            if prominent {
                buttonStyle(.glassProminent)
            } else {
                buttonStyle(.glass)
            }
        } else if prominent {
            buttonStyle(.borderedProminent)
        } else {
            buttonStyle(.bordered)
        }
    }
}

extension View {
    func topBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        modifier(TopBarModifier(bar: bar))
    }
}
