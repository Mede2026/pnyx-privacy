import QRCore
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Sauvegarde manuelle en fichier : iCloud synchronise, mais ne sauvegarde pas.
struct BackupSection: View {
    @Environment(AppServices.self) private var services
    @Environment(\.modelContext) private var context
    @State private var exportDocument: BackupFile?
    @State private var isExporting = false
    @State private var isImportingBackup = false
    @State private var isImportingCSV = false
    @State private var pendingBackup: BackupDocument?
    @State private var isConfirmingReplace = false
    @State private var localCount = 0

    var body: some View {
        Section {
            Button {
                prepareExport()
            } label: {
                Label("Sauvegarder dans un fichier…", systemImage: "externaldrive.badge.plus")
            }
            Button {
                isImportingBackup = true
            } label: {
                Label("Restaurer une sauvegarde…", systemImage: "externaldrive.badge.timemachine")
            }
            Button {
                isImportingCSV = true
            } label: {
                Label("Importer un CSV…", systemImage: "tablecells.badge.ellipsis")
            }
        } header: {
            Text("Sauvegarde")
        } footer: {
            Text("Un seul fichier .json avec tous les codes, dossiers, styles, préréglages, logos et sites de recherche. Enregistrez-le où vous voulez : Fichiers, un disque, une clé USB.")
        }
        .fileExporter(isPresented: $isExporting, document: exportDocument, contentType: .json,
                      defaultFilename: "QR Studio \(Date.now.formatted(date: .numeric, time: .omitted))") { result in
            if case .failure(let error) = result { services.alerts.show(error) }
        }
        .fileImporter(isPresented: $isImportingBackup, allowedContentTypes: [.json]) { result in
            loadBackup(result)
        }
        .fileImporter(isPresented: $isImportingCSV, allowedContentTypes: [.commaSeparatedText, .plainText]) { result in
            importCSV(result)
        }
        .confirmationDialog("Restaurer cette sauvegarde ?", isPresented: Binding(
            get: { pendingBackup != nil && !isConfirmingReplace }, set: { if !$0 && !isConfirmingReplace { pendingBackup = nil } }
        ), titleVisibility: .visible) {
            Button("Fusionner") { restore(.merge) }
            Button("Tout remplacer…", role: .destructive) { isConfirmingReplace = true }
        } message: {
            Text("Le fichier contient \(pendingBackup?.entries.count ?? 0) codes. Fusionner ajoute ceux qui manquent ; Remplacer efface d’abord cet historique. L’import se propage aussi à iCloud et à vos autres appareils.")
        }
        .alert("Remplacer votre historique ?", isPresented: $isConfirmingReplace) {
            Button("Annuler", role: .cancel) { pendingBackup = nil }
            Button("Remplacer", role: .destructive) { restore(.replace) }
        } message: {
            Text("Les \(localCount) codes de cet appareil seront supprimés et remplacés par les \(pendingBackup?.entries.count ?? 0) codes du fichier, sur tous vos appareils. Cette action est irréversible.")
        }
    }

    private func prepareExport() {
        do {
            exportDocument = BackupFile(data: try BackupCodec.export(from: context))
            isExporting = true
        } catch {
            services.alerts.show(error, title: String(localized: "La sauvegarde a échoué"))
        }
    }

    private func loadBackup(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let data = try SecurityScoped.read(url)
            pendingBackup = try BackupCodec.decode(data)
            localCount = try BackupCodec.entryCount(in: context)
        } catch {
            services.alerts.show(error, title: String(localized: "La restauration a échoué"))
        }
    }

    private func restore(_ mode: BackupCodec.ImportMode) {
        guard let document = pendingBackup else { return }
        pendingBackup = nil
        isConfirmingReplace = false
        do {
            let summary = try BackupCodec.restore(document, into: context, mode: mode)
            services.store.updated([])
            services.alerts.show(title: String(localized: "Sauvegarde restaurée"),
                                 detail: String(localized: "\(summary.added) codes ajoutés, \(summary.skipped) déjà présents."))
        } catch {
            services.alerts.show(error, title: String(localized: "La restauration a échoué"))
        }
    }

    private func importCSV(_ result: Result<URL, Error>) {
        do {
            let count = CSVImport.run(try SecurityScoped.read(try result.get()), into: services.store)
            services.alerts.show(title: String(localized: "Import terminé"),
                                 detail: String(localized: "\(count) codes importés."))
        } catch {
            services.alerts.show(error, title: String(localized: "L’import a échoué"))
        }
    }
}
