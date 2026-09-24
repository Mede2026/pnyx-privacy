import QRCore
import SwiftUI

/// Export d'une liste de codes : CSV annoté, planche PDF multipage.
struct ExportEntriesSheet: View {
    let entries: [CodeEntry]
    let title: String
    @Environment(\.dismiss) private var dismiss
    @Environment(AlertCenter.self) private var alerts
    @State private var csvURL: URL?
    @State private var pdfURL: URL?
    @State private var jsonURL: URL?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Codes", value: "\(entries.count)")
                }
                Section {
                    exportRow(url: csvURL, title: "Tableur CSV", subtitle: "Numbers, Excel, Google Sheets", icon: "tablecells")
                    exportRow(url: pdfURL, title: "Planche PDF", subtitle: "Une grille imprimable de codes avec légendes", icon: "doc.richtext")
                    exportRow(url: jsonURL, title: "Fichier JSON", subtitle: "Réimportable dans QR Studio, avec styles et dossiers", icon: "curlybraces")
                } footer: {
                    Text("Colonnes : date, contenu, symbologie, type, libellé, quantité, note, dossier, origine.")
                }
            }
            .navigationTitle("Exporter")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .task {
                let name = "\(title) \(Date.now.formatted(date: .numeric, time: .omitted))"
                do {
                    csvURL = try ExportService.csvFile(for: entries, name: name)
                    jsonURL = try ExportService.jsonFile(for: entries, name: name)
                    pdfURL = try await ExportService.pdfSheet(for: entries, name: name)
                } catch {
                    alerts.show(error, title: String(localized: "L’export a échoué"))
                }
            }
        }
        .alertHost()
    }

    @ViewBuilder
    private func exportRow(url: URL?, title: LocalizedStringKey, subtitle: LocalizedStringKey, icon: String) -> some View {
        if let url {
            ShareLink(item: url) {
                Label {
                    VStack(alignment: .leading) {
                        Text(title)
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: icon)
                }
            }
        } else {
            HStack {
                ProgressView()
                Text(title).foregroundStyle(.secondary)
            }
        }
    }
}
