import QRCore
import SwiftUI

/// Couleurs : modules (unie ou dégradé), fond (uni ou transparent), yeux (contour et centre).
struct ColorsTab: View {
    @Binding var style: StyleConfig

    var body: some View {
        Section("Modules") {
            ColorPicker("Couleur", selection: color(\.foreground), supportsOpacity: false)
            Picker("Dégradé", selection: $style.gradientKind) {
                Text("Aucun").tag(GradientKind.none)
                Text("Linéaire").tag(GradientKind.linear)
                Text("Radial").tag(GradientKind.radial)
            }
            if style.gradientKind != .none {
                ColorPicker("Couleur de fin", selection: optionalColor(\.gradientEnd, fallback: style.foreground),
                            supportsOpacity: false)
            }
        }
        Section("Fond") {
            Toggle("Transparent", isOn: Binding(
                get: { style.background == nil },
                set: { style.background = $0 ? nil : .white }
            ))
            if style.background != nil {
                ColorPicker("Couleur", selection: optionalColor(\.background, fallback: .white), supportsOpacity: false)
            }
        }
        Section("Yeux") {
            OptionalColorRow(title: "Couleur du contour", color: $style.eyeFrameColor, fallback: style.foreground)
            OptionalColorRow(title: "Couleur du centre", color: $style.eyeBallColor, fallback: style.eyeFrameColor ?? style.foreground)
        }
    }

    private func color(_ keyPath: WritableKeyPath<StyleConfig, RGBAColor>) -> Binding<Color> {
        Binding(
            get: { style[keyPath: keyPath].color },
            set: { style[keyPath: keyPath] = RGBAColor($0.resolve(in: EnvironmentValues())) }
        )
    }

    private func optionalColor(_ keyPath: WritableKeyPath<StyleConfig, RGBAColor?>, fallback: RGBAColor) -> Binding<Color> {
        Binding(
            get: { (style[keyPath: keyPath] ?? fallback).color },
            set: { style[keyPath: keyPath] = RGBAColor($0.resolve(in: EnvironmentValues())) }
        )
    }
}
