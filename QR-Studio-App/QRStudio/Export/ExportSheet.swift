import QRCore
import SwiftUI

/// Export d'un code : format, taille, partage, Photos, impression.
struct ExportSheet: View {
    let request: RenderRequest
    let suggestedName: String
    @Environment(\.dismiss) private var dismiss
    @Environment(AlertCenter.self) private var alerts
    @State private var format: ExportFormat = .png
    @State private var size = 1024
    @State private var fileURL: URL?
    @State private var isWorking = false
    @State private var savedToPhotos = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    CodePreview(request: request, pixelWidth: 600)
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                        .listRowBackground(Color.clear)
                }
                Section {
                    Picker("Format", selection: $format) {
                        ForEach(ExportFormat.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Picker("Taille", selection: $size) {
                        ForEach(ExportService.sizes, id: \.self) { Text("\($0) px").tag($0) }
                    }
                    .pickerStyle(.segmented)
                } footer: {
                    Text(format == .pdf || format == .svg
                         ? "Format vectoriel : net à toutes les tailles."
                         : "La taille est la largeur en pixels.")
                }
                Section {
                    if let fileURL {
                        ShareLink(item: fileURL) {
                            Label("Partager", systemImage: "square.and.arrow.up")
                        }
                    } else {
                        HStack {
                            ProgressView()
                            Text("Préparation…").foregroundStyle(.secondary)
                        }
                    }
                    Button {
                        Task { await saveToPhotos() }
                    } label: {
                        Label(savedToPhotos ? "Enregistré dans Photos" : "Enregistrer dans Photos",
                              systemImage: savedToPhotos ? "checkmark" : "photo.badge.plus")
                    }
                    .disabled(isWorking)
                    Button {
                        Task { await printCode() }
                    } label: {
                        Label("Imprimer", systemImage: "printer")
                    }
                }
            }
            .navigationTitle("Exporter")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
            .task(id: "\(format.rawValue)-\(size)") {
                fileURL = nil
                do {
                    fileURL = try await ExportService.file(for: request, format: format, size: size, name: suggestedName)
                } catch {
                    alerts.show(error, title: String(localized: "L’export a échoué"))
                }
            }
        }
        .alertHost()
    }

    private func saveToPhotos() async {
        isWorking = true
        defer { isWorking = false }
        do {
            try await ExportService.saveToPhotos(request, size: size)
            savedToPhotos = true
        } catch {
            alerts.show(error, title: String(localized: "Non enregistré"))
        }
    }

    private func printCode() async {
        do {
            try await ExportService.print(request, name: suggestedName)
        } catch {
            alerts.show(error, title: String(localized: "L’impression a échoué"))
        }
    }
}
