import QRCore
import SwiftUI

/// Menus Fichier, Édition, Présentation et Aide d'une vraie app Mac, avec ⌘N, ⌘F, ⌘S.
struct MacCommands: Commands {
    let services: AppServices
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    private var selectedEntry: CodeEntry? {
        services.selectedEntryID.flatMap { services.store.fetchEntry(id: $0) }
    }

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Nouveau code…") { services.isGeneratorPresented = true }
                .keyboardShortcut("n")
            Button("Scanner avec la caméra…") { services.isScannerPresented = true }
                .keyboardShortcut("k")
            Divider()
            Button("Ouvrir une image…") { MacImageImporter.chooseImage() }
                .keyboardShortcut("o")
            Button("Importer un fichier CSV…") { MacImageImporter.chooseCSV() }
        }
        CommandGroup(replacing: .saveItem) {
            Button("Exporter le code…") { services.isExportPresented = true }
                .keyboardShortcut("s")
                .disabled(services.selectedEntryID == nil)
            Button("Sauvegarde et restauration…") { openSettings() }
        }
        // Après les commandes système (Couper, Copier, Coller) : les champs de texte les gardent.
        CommandGroup(after: .pasteboard) {
            Divider()
            Button("Copier le contenu") {
                if let entry = selectedEntry { Pasteboard.copy(entry.rawValue) }
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .disabled(services.selectedEntryID == nil)
            Button("Copier l’image du code") {
                guard let entry = selectedEntry else { return }
                let request = entry.previewRequest
                Task { await Self.copyImage(request) }
            }
            .keyboardShortcut("c", modifiers: [.command, .option])
            .disabled(services.selectedEntryID == nil)
            Button("Coller une image ou un texte") { MacImageImporter.paste() }
                .keyboardShortcut("v", modifiers: [.command, .shift])
            Divider()
            Button(selectedEntry?.isFavorite == true ? "Retirer des favoris" : "Ajouter aux favoris") {
                guard let entry = selectedEntry else { return }
                entry.isFavorite.toggle()
                services.store.updated([entry])
            }
            .keyboardShortcut("d")
            .disabled(services.selectedEntryID == nil)
            Button("Placer dans la corbeille") {
                guard let entry = selectedEntry else { return }
                services.store.moveToTrash([entry])
                services.selectedEntryID = nil
            }
            .keyboardShortcut(.delete)
            .disabled(services.selectedEntryID == nil || selectedEntry?.deletedAt != nil)
        }
        CommandGroup(after: .textEditing) {
            Button("Rechercher") { services.isSearchFocused = true }
                .keyboardShortcut("f")
        }
        CommandGroup(before: .sidebar) {
            Button("Carte des scans") { services.sidebar = .map }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            Button("Scans reçus de l’iPhone") { openWindow(id: "received") }
                .keyboardShortcut("r", modifiers: [.command, .shift])
            Divider()
        }
        CommandGroup(replacing: .help) {
            Button("Aide de QR Studio") { openWindow(id: "help") }
                .keyboardShortcut("?")
        }
    }

    private static func copyImage(_ request: RenderRequest) async {
        do {
            let data = try await CodeRenderer.shared.drawing(for: request).pngData(width: 1024)
            if let image = NSImage(data: data) { Pasteboard.copy(image: image) }
        } catch {
            AppServices.shared.alerts.show(error)
        }
    }
}
