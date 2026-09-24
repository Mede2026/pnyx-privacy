import QRCore
import SwiftUI

/// Couleur facultative : désactivée, elle reprend la couleur des modules.
struct OptionalColorRow: View {
    let title: LocalizedStringKey
    @Binding var color: RGBAColor?
    let fallback: RGBAColor

    var body: some View {
        Toggle(title, isOn: Binding(get: { color != nil }, set: { color = $0 ? fallback : nil }))
        if let current = color {
            ColorPicker(title, selection: Binding(
                get: { current.color },
                set: { color = RGBAColor($0.resolve(in: EnvironmentValues())) }
            ), supportsOpacity: false)
        }
    }
}
