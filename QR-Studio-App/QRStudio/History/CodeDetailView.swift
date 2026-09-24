import MapKit
import QRCore
import SwiftData
import SwiftUI

/// Détail d'un code : grand aperçu, métadonnées, actions et édition.
struct CodeDetailView: View {
    let entryID: UUID
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var entry: CodeEntry?
    @State private var actions = ActionHandler()
    @State private var isEditingStyle = false
    @State private var isExporting = false
    @State private var isChoosingFolder = false
    @State private var isPresentingFullScreen = false

    var body: some View {
        Group {
            if let entry {
                content(entry)
            } else {
                ContentUnavailableView("Code introuvable", systemImage: "questionmark.square.dashed",
                                       description: Text("Ce code a peut-être été supprimé sur un autre appareil."))
            }
        }
        .onAppear {
            actions.alerts = services.alerts
            entry = services.store.fetchEntry(id: entryID)
        }
        .actionPresentations(actions)
        .alertHost()
    }

    private func content(_ entry: CodeEntry) -> some View {
        let parsed = ScannedContentParser.parse(entry.rawValue, symbology: entry.symbologyKind)
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    isPresentingFullScreen = true
                } label: {
                    CodePreview(request: entry.previewRequest)
                        .frame(maxWidth: 420, maxHeight: 420)
                        .padding(12)
                        .background(Color.white, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text("Affiche le code en plein écran à luminosité maximale"))

                DetailEditor(entry: entry, onChooseFolder: { isChoosingFolder = true })
                DetailMetadata(entry: entry)
                ContentDetailCard(parsed: parsed, actions: actions)
                ContentActionsView(parsed: parsed, raw: entry.rawValue, actions: actions, entry: entry)
            }
            .padding()
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
        .background(Color.groupedBackground)
        .navigationTitle(entry.displayTitle)
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    entry.isFavorite.toggle()
                    services.store.updated([entry])
                } label: {
                    Label(entry.isFavorite ? "Retirer des favoris" : "Ajouter aux favoris",
                          systemImage: entry.isFavorite ? "star.fill" : "star")
                }
                Menu {
                    if entry.renderRequest.symbology.supportsFullStyling {
                        Button("Modifier le style", systemImage: "paintbrush") { isEditingStyle = true }
                    }
                    Button("Exporter…", systemImage: "square.and.arrow.up") { isExporting = true }
                    Button("Dupliquer", systemImage: "plus.square.on.square") { _ = services.store.duplicate(entry) }
                    Divider()
                    Button("Supprimer", systemImage: "trash", role: .destructive) {
                        services.store.moveToTrash([entry])
                        dismiss()
                    }
                } label: {
                    Label("Plus", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $isEditingStyle) {
            NavigationStack { EntryStyleEditor(entry: entry) }
        }
        .sheet(isPresented: $isExporting) {
            ExportSheet(request: entry.previewRequest, suggestedName: entry.displayTitle)
        }
        .sheet(isPresented: $isChoosingFolder) {
            FolderPickerSheet { folder in
                entry.folder = folder
                services.store.updated([entry])
            }
        }
        .fullScreenCover(isPresented: $isPresentingFullScreen) {
            FullScreenCodeView(request: entry.previewRequest, title: entry.displayTitle)
        }
    }
}
