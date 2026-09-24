import QRCore
import SwiftUI

/// Zone silencieuse, correction d'erreur, cadre et légende.
struct AdvancedTab: View {
    @Binding var style: StyleConfig

    var body: some View {
        Section {
            Stepper(value: $style.quietZone, in: StyleConfig.quietZoneRange) {
                LabeledContent("Zone silencieuse", value: String(localized: "\(style.quietZone) modules"))
            }
        } footer: {
            if style.quietZone < StyleConfig.recommendedQuietZone {
                Label("Au moins 4 modules sont recommandés pour une lecture fiable.", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
            }
        }
        Section {
            Picker("Correction d’erreur", selection: $style.errorCorrection) {
                ForEach(ErrorCorrection.allCases) { level in
                    Text("\(level.rawValue) — \(level.recoveryPercent) %").tag(level)
                }
            }
            .disabled(style.hasLogo)
        } footer: {
            if style.hasLogo {
                Text("Réglé sur H, car le code contient un logo.")
            } else {
                Text("Un niveau élevé résiste mieux aux dommages, mais rend le code plus dense.")
            }
        }
        Section("Cadre") {
            Toggle("Cadre et légende", isOn: $style.frameEnabled)
            if style.frameEnabled {
                TextField("Légende, par exemple Scannez-moi", text: $style.caption)
                ColorPicker("Couleur du cadre", selection: Binding(
                    get: { (style.frameColor ?? style.foreground).color },
                    set: { style.frameColor = RGBAColor($0.resolve(in: EnvironmentValues())) }
                ), supportsOpacity: false)
            }
        }
    }
}
