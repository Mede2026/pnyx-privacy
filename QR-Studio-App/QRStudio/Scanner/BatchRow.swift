import QRCore
import SwiftData
import SwiftUI

struct BatchRow: View {
    @Bindable var entry: CodeEntry
    @Environment(AppServices.self) private var services

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: entry.contentKind.symbolName)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.summary)
                    .font(.subheadline.monospaced())
                    .lineLimit(1)
                TextField("Note", text: $entry.note)
                    .font(.caption)
                    .onSubmit { services.store.updated([entry]) }
            }
            Spacer()
            Stepper(value: $entry.quantity, in: 1...9999) {
                Text("×\(entry.quantity)")
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
            .fixedSize()
            .onChange(of: entry.quantity) { services.store.updated([entry]) }
            .accessibilityLabel(Text("Quantité"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
