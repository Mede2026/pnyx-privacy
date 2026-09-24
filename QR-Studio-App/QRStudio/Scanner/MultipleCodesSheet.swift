import QRCore
import SwiftUI

/// Plusieurs codes dans le champ ou dans une image : l'utilisateur choisit.
struct MultipleCodesSheet: View {
    let codes: [DetectedBarcode]
    let onChoose: (DetectedBarcode) -> Void

    var body: some View {
        NavigationStack {
            List(codes) { code in
                let parsed = ScannedContentParser.parse(code.payload, symbology: code.symbology)
                Button {
                    onChoose(code)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: parsed.contentType.symbolName)
                            .font(.title3)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(parsed.contentType.title)
                                .font(.headline)
                            Text(code.payload)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                            Text(code.symbology.displayName)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
            .navigationTitle(Text("\(codes.count) codes trouvés"))
            .inlineNavigationTitle()
        }
        .sheetHeight(.mediumAndLarge)
        .alertHost()
    }
}
