import AppKit
import QRCore
import UniformTypeIdentifiers

/// Lecture des codes d'images venues du Mac : glisser-déposer, Fichier › Ouvrir, Édition › Coller.
@MainActor
enum MacImageImporter {
    static func decode(files urls: [URL]) async {
        var images: [Data] = []
        do {
            for url in urls {
                let accessed = url.startAccessingSecurityScopedResource()
                defer { if accessed { url.stopAccessingSecurityScopedResource() } }
                images.append(try Data(contentsOf: url))
            }
        } catch {
            AppServices.shared.alerts.show(error, title: String(localized: "Image illisible"))
            return
        }
        await decode(images: images)
    }

    static func decode(images: [Data]) async {
        let services = AppServices.shared
        var found: [DetectedBarcode] = []
        do {
            for data in images {
                found += try await Task.detached(priority: .userInitiated) {
                    try ImageBarcodeDecoder.decode(imageData: data)
                }.value
            }
        } catch {
            services.alerts.show(error, title: String(localized: "Image illisible"))
            return
        }
        guard !found.isEmpty else {
            services.alerts.show(title: String(localized: "Rien à lire"),
                                 detail: String(localized: "Aucun code n’a été trouvé dans cette image."))
            return
        }
        var lastID: UUID?
        for code in found {
            lastID = services.store.recordScan(payload: code.payload, symbology: code.symbology).id
        }
        services.sidebar = .allCodes
        services.selectedEntryID = lastID
    }

    /// Fichier › Ouvrir une image…
    static func chooseImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image, .pdf]
        panel.allowsMultipleSelection = true
        panel.message = String(localized: "Choisissez une image contenant un code.")
        guard panel.runModal() == .OK else { return }
        let urls = panel.urls
        Task { await decode(files: urls) }
    }

    /// Édition › Coller : une image est décodée, un texte ouvre le générateur prérempli.
    static func paste() {
        let pasteboard = NSPasteboard.general
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL],
           !urls.isEmpty {
            Task { await decode(files: urls) }
        } else if let image = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff) {
            Task { await decode(images: [image]) }
        } else if let text = pasteboard.string(forType: .string), !text.isEmpty {
            AppServices.shared.generatorPrefill = text
            AppServices.shared.isGeneratorPresented = true
        } else {
            AppServices.shared.alerts.show(title: String(localized: "Rien à coller"),
                                           detail: String(localized: "Le presse-papier ne contient ni image ni texte."))
        }
    }

    /// Fichier › Importer un CSV…
    static func chooseCSV() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText, .plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let services = AppServices.shared
        do {
            let count = CSVImport.run(try Data(contentsOf: url), into: services.store)
            services.alerts.show(title: String(localized: "Import terminé"),
                                 detail: String(localized: "\(count) codes importés."))
        } catch {
            services.alerts.show(error, title: String(localized: "L’import a échoué"))
        }
    }
}
