import QRCore
import SwiftUI

/// Formats lus en mode lot quand le préréglage « Formats choisis » est actif.
/// Moins de formats à tester par image : détection plus rapide, moins de faux positifs.
struct BatchSymbologiesView: View {
    @Environment(AppSettings.self) private var settings

    private static let choices: [Symbology] = Symbology.allCases.filter { $0 != .unknown }

    var body: some View {
        List {
            Section {
                ForEach(Self.choices) { symbology in
                    Button {
                        toggle(symbology)
                    } label: {
                        HStack {
                            Text(verbatim: symbology.displayName)
                                .foregroundStyle(.primary)
                            Spacer()
                            if settings.customBatchSymbologies.contains(symbology) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    .accessibilityAddTraits(settings.customBatchSymbologies.contains(symbology) ? .isSelected : [])
                }
            } footer: {
                Text("Aucun format coché : tous les formats sont lus.")
            }
        }
        .navigationTitle("Formats en mode lot")
    }

    private func toggle(_ symbology: Symbology) {
        if settings.customBatchSymbologies.contains(symbology) {
            settings.customBatchSymbologies.remove(symbology)
        } else {
            settings.customBatchSymbologies.insert(symbology)
        }
    }
}
