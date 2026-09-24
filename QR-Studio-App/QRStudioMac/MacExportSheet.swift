import QRCore
import SwiftUI
import UniformTypeIdentifiers

/// Export d'un code : format et taille, puis panneau d'enregistrement.
struct MacExportSheet: View {
    let request: RenderRequest
    let name: String
    @Environment(\.dismiss) private var dismiss
    @Environment(AlertCenter.self) private var alerts
    @State private var format: MacExport.Format = .png
    @State private var size = 1024
    @State private var document: ExportedFile?
    @State private var isSaving = false

    var body: some View {
        Form {
            Picker("Format", selection: $format) {
                ForEach(MacExport.Format.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            Picker("Taille", selection: $size) {
                ForEach(MacExport.sizes, id: \.self) { Text("\($0) px").tag($0) }
            }
            .pickerStyle(.segmented)
            Text(format == .pdf || format == .svg ? "Format vectoriel : net à toutes les tailles." : "La taille est la largeur en pixels.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Annuler") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Exporter…") { Task { await prepare() } }
            }
        }
        .fileExporter(isPresented: $isSaving, document: document, contentType: format.contentType,
                      defaultFilename: MacExport.safeFileName(name)) { result in
            switch result {
            case .success: dismiss()
            case .failure(let error): alerts.show(error, title: String(localized: "L’export a échoué"))
            }
        }
    }

    private func prepare() async {
        do {
            document = ExportedFile(data: try await MacExport.data(for: request, format: format, size: size))
            isSaving = true
        } catch {
            alerts.show(error, title: String(localized: "L’export a échoué"))
        }
    }
}
