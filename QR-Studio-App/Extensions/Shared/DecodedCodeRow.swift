import QRCore
import SwiftUI

/// Un code décodé : type, contenu, copier et enregistrer.
struct DecodedCodeRow: View {
    let code: DetectedBarcode
    let model: ExtensionModel

    var body: some View {
        let parsed = ScannedContentParser.parse(code.payload, symbology: code.symbology)
        VStack(alignment: .leading, spacing: 10) {
            Label(parsed.contentType.title, systemImage: parsed.contentType.symbolName)
                .font(.headline)
            Text(code.payload)
                .font(.body)
                .textSelection(.enabled)
                .lineLimit(6)
            Text(code.symbology.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Button("Copier", systemImage: "doc.on.doc") { model.copy(code.payload) }
                    .buttonStyle(.bordered)
                Button(model.savedPayloads.contains(code.payload) ? "Enregistré" : "Enregistrer",
                       systemImage: model.savedPayloads.contains(code.payload) ? "checkmark" : "tray.and.arrow.down") {
                    model.save(payload: code.payload, symbology: code.symbology, origin: .scanned)
                }
                .buttonStyle(.borderedProminent)
                .disabled(model.savedPayloads.contains(code.payload))
            }
            Button("Ouvrir dans QR Studio", systemImage: "arrow.up.forward.app") {
                model.openInApp(payload: code.payload, symbology: code.symbology)
            }
            .font(.callout)
        }
        .padding(.vertical, 6)
    }
}
