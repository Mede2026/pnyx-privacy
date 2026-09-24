import QRCore
import SwiftUI

/// Fenêtre « Scans reçus » (mode Liste), exportable en CSV.
struct ReceivedScansView: View {
    @Environment(MacLinkServer.self) private var server
    @Environment(AlertCenter.self) private var alerts
    @State private var document: ExportedFile?
    @State private var isExporting = false

    var body: some View {
        List(server.received) { item in
            HStack {
                Text(item.message.payload).textSelection(.enabled).lineLimit(2)
                Spacer()
                Text(item.message.date, format: .dateTime.hour().minute().second())
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .contextMenu {
                Button("Copier") { Pasteboard.copy(item.message.payload) }
            }
        }
        .overlay {
            if server.received.isEmpty {
                ContentUnavailableView("Aucun scan reçu", systemImage: "iphone.gen3.radiowaves.left.and.right",
                                       description: Text("Activez l’envoi depuis la puce du scanner sur l’iPhone."))
            }
        }
        .toolbar {
            Button("Exporter en CSV…") {
                let rows = server.received.map {
                    ExportRow(date: $0.message.date, content: $0.message.payload,
                              symbology: Symbology(storedValue: $0.message.symbology).displayName,
                              type: ScannedContentParser.parse($0.message.payload).contentType.title,
                              label: "", quantity: 1, note: "", folder: "", origin: String(localized: "Scanné"))
                }
                document = ExportedFile(data: CSVExporter.csv(rows))
                isExporting = true
            }
            .disabled(server.received.isEmpty)
            Button("Tout effacer") { server.clearReceived() }
                .disabled(server.received.isEmpty)
        }
        .fileExporter(isPresented: $isExporting, document: document, contentType: .commaSeparatedText,
                      defaultFilename: "Scans reçus") { result in
            if case .failure(let error) = result { alerts.show(error) }
        }
        .frame(minWidth: 420, minHeight: 320)
    }
}
