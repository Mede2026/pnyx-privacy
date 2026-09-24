import QRCore
import SwiftData
import SwiftUI

/// Fenêtre principale : dossiers à gauche, liste au centre, aperçu à droite.
struct MacSplitView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var services = services
        NavigationSplitView {
            MacSidebar()
        } content: {
            if services.sidebar == .map {
                NavigationStack { ScanMapView() }
                    .navigationSplitViewColumnWidth(min: 360, ideal: 520)
            } else {
                MacHistoryList(filter: (services.sidebar ?? .allCodes).filter)
                    .id(services.sidebar)
                    .navigationSplitViewColumnWidth(min: 280, ideal: 340)
            }
        } detail: {
            if let id = services.selectedEntryID {
                MacDetailView(entryID: id).id(id)
            } else {
                ContentUnavailableView("Aucun code sélectionné", systemImage: "qrcode",
                                       description: Text("Choisissez un code, créez-en un (⌘N) ou déposez une image sur la fenêtre."))
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    services.isScannerPresented = true
                } label: {
                    Label("Scanner", systemImage: "camera.viewfinder")
                }
                .help("Scanner avec la caméra (⌘K)")
                Button {
                    services.isGeneratorPresented = true
                } label: {
                    Label("Nouveau code", systemImage: "plus")
                }
                .help("Nouveau code (⌘N)")
            }
        }
        .imageDropZone()
        // Codes arrivés par iCloud ou l'extension depuis la dernière fois : indexés pour Spotlight.
        .onChange(of: scenePhase, initial: true) { _, phase in
            if phase == .active { services.spotlight.indexNewEntries(context: services.container.mainContext) }
        }
        // ⌘V hors d'un champ de texte : image décodée, ou texte vers le générateur.
        .onPasteCommand(of: [.image, .fileURL, .plainText]) { _ in MacImageImporter.paste() }
        .alertHost()
        .sheet(isPresented: $services.isGeneratorPresented) {
            MacGeneratorView()
        }
        .sheet(isPresented: $services.isScannerPresented) {
            MacScannerView()
        }
    }
}
