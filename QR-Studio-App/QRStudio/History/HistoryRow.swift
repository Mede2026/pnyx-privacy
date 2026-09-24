import QRCore
import SwiftUI

/// Rangée : vignette, contenu tronqué, icône du type détecté et heure.
struct HistoryRow: View {
    let entry: CodeEntry

    var body: some View {
        HStack(spacing: 12) {
            CodeThumbnail(entry: entry)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: entry.contentKind.symbolName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(entry.displayTitle)
                        .font(.headline)
                        .lineLimit(1)
                    if entry.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption2)
                            .foregroundStyle(.yellow)
                            .accessibilityLabel(Text("Favori"))
                    }
                }
                Text(entry.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(entry.createdAt, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                if entry.quantity > 1 {
                    Text("×\(entry.quantity)")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                }
                Image(systemName: entry.originKind == .scanned ? "camera.viewfinder" : "wand.and.stars")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .accessibilityLabel(entry.originKind == .scanned ? Text("Scannés") : Text("Créés"))
            }
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}
