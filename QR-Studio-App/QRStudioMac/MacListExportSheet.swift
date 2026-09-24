import QRCore
import SwiftUI
import UniformTypeIdentifiers

/// Export d'une liste : CSV annoté ou planche PDF.
struct MacListExportSheet: View {
    let entries: [CodeEntry]
    @Environment(\.dismiss) private var dismiss
    @Environment(AlertCenter.self) private var alerts
    @State private var document: ExportedFile?
    @State private var contentType: UTType = .commaSeparatedText
    @State private var isSaving = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Exporter \(entries.count) codes").font(.headline)
            Button {
                document = ExportedFile(data: CSVExporter.csv(entries.map(ExportRow.init)))
                contentType = .commaSeparatedText
                isSaving = true
            } label: {
                Label("Tableur CSV (Numbers, Excel)", systemImage: "tablecells")
            }
            Button {
                do {
                    document = ExportedFile(data: try BackupCodec.export(entries: entries))
                    contentType = .json
                    isSaving = true
                } catch {
                    alerts.show(error, title: String(localized: "L’export a échoué"))
                }
            } label: {
                Label("Fichier JSON (réimportable dans QR Studio)", systemImage: "curlybraces")
            }
            Button {
                Task { await preparePDF() }
            } label: {
                Label("Planche PDF imprimable", systemImage: "doc.richtext")
            }
            Text("Colonnes : date, contenu, symbologie, type, libellé, quantité, note, dossier, origine.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("Fermer") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(20)
        .frame(width: 420)
        .fileExporter(isPresented: $isSaving, document: document, contentType: contentType,
                      defaultFilename: "QR Studio \(Date.now.formatted(date: .numeric, time: .omitted))") { result in
            if case .failure(let error) = result { alerts.show(error, title: String(localized: "L’export a échoué")) }
        }
    }

    private func preparePDF() async {
        let items = entries.map {
            PDFSheetExporter.Item(request: $0.previewRequest, title: $0.displayTitle, subtitle: String($0.summary.prefix(60)))
        }
        do {
            document = ExportedFile(data: try await PDFSheetExporter.pdf(items))
            contentType = .pdf
            isSaving = true
        } catch {
            alerts.show(error, title: String(localized: "L’export a échoué"))
        }
    }
}
