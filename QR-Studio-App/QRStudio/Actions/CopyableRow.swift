import SwiftUI

/// Une valeur sur sa ligne, avec un bouton de copie.
struct CopyableRow: View {
    let title: LocalizedStringKey
    let value: String
    var monospaced = false
    var isSecret = false
    let onCopy: (String) -> Void
    @State private var isRevealed = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Group {
                    if isSecret && !isRevealed {
                        Text(String(repeating: "•", count: min(max(value.count, 6), 16)))
                            .accessibilityLabel(Text("Masqué"))
                    } else {
                        Text(value)
                            .textSelection(.enabled)
                    }
                }
                .font(monospaced ? .body.monospaced() : .body)
            }
            Spacer(minLength: 8)
            if isSecret {
                Button {
                    isRevealed.toggle()
                } label: {
                    Image(systemName: isRevealed ? "eye.slash" : "eye")
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel(isRevealed ? Text("Masquer") : Text("Afficher"))
            }
            Button {
                onCopy(value)
            } label: {
                Image(systemName: "doc.on.doc")
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(Text("Copier \(Text(title))"))
        }
        .padding(.vertical, 4)
    }
}
