import QRCore
import SwiftUI

/// Vert si le code se relit, rouge sinon. Avertissements de contraste en dessous.
struct ReadabilityIndicator: View {
    let readability: Readability?
    let colorCheck: ColorCheck

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if colorCheck.isContrastTooLow {
                Label("Contraste trop faible (\(colorCheck.contrastRatio, format: .number.precision(.fractionLength(1))):1, minimum 4:1). Foncez le code ou éclaircissez le fond.",
                      systemImage: "exclamationmark.octagon.fill")
                    .foregroundStyle(.red)
            } else if colorCheck.isInverted {
                Label("Code clair sur fond sombre : beaucoup de lecteurs échouent.", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            }
            switch readability {
            case .none:
                EmptyView()
            case .checking:
                Label("Vérification de la lisibilité…", systemImage: "hourglass")
                    .foregroundStyle(.secondary)
            case .readable:
                Label("Lisible : le code a été relu avec succès", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            case .unreadable(let reason):
                Label(reason, systemImage: "xmark.seal.fill")
                    .foregroundStyle(.red)
            case .unverified(let reason):
                Label(reason, systemImage: "questionmark.circle.fill")
                    .foregroundStyle(.orange)
            }
        }
        .font(.footnote.weight(.medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}
