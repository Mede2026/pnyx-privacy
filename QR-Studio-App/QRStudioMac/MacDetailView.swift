import QRCore
import SwiftData
import SwiftUI

/// Aperçu à droite : grand code (qu'on peut glisser), métadonnées, actions, édition.
struct MacDetailView: View {
    let entryID: UUID
    @Environment(AppServices.self) private var services
    @State private var entry: CodeEntry?
    @State private var actions = ActionHandler()
    @State private var isEditingStyle = false
    @State private var isChoosingFolder = false

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
        .overlay(alignment: .top) {
            if let toast = actions.toast {
                Text(toast)
                    .font(.callout.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, 12)
                    .task(id: toast) {
                        do {
                            try await Task.sleep(for: .seconds(1.5))
                            actions.toast = nil
                        } catch {
                            return
                        }
                    }
            }
        }
    }

    private func content(_ entry: CodeEntry) -> some View {
        @Bindable var services = services
        let parsed = ScannedContentParser.parse(entry.rawValue, symbology: entry.symbologyKind)
        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CodePreview(request: entry.previewRequest, pixelWidth: 900)
                    .frame(maxWidth: 360, maxHeight: 360)
                    .padding(14)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .frame(maxWidth: .infinity)
                    .draggable(DraggableCode(entry: entry))
                    .help("Glissez le code vers le Finder ou une autre app")
                DetailEditor(entry: entry, onChooseFolder: { isChoosingFolder = true })
                DetailMetadata(entry: entry)
                ContentDetailCard(parsed: parsed, actions: actions)
                ContentActionsView(parsed: parsed, raw: entry.rawValue, actions: actions, entry: entry)
            }
            .padding(20)
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(entry.displayTitle)
        .toolbar {
            ToolbarItemGroup {
                Button {
                    entry.isFavorite.toggle()
                    services.store.updated([entry])
                } label: {
                    Label(entry.isFavorite ? "Retirer des favoris" : "Ajouter aux favoris",
                          systemImage: entry.isFavorite ? "star.fill" : "star")
                }
                if entry.renderRequest.symbology.supportsFullStyling {
                    Button {
                        isEditingStyle = true
                    } label: {
                        Label("Modifier le style", systemImage: "paintbrush")
                    }
                }
                Button {
                    services.isExportPresented = true
                } label: {
                    Label("Exporter", systemImage: "square.and.arrow.up")
                }
            }
        }
        .sheet(isPresented: $isEditingStyle) {
            NavigationStack { EntryStyleEditor(entry: entry) }
                .frame(minWidth: 560, minHeight: 640)
        }
        .sheet(isPresented: $isChoosingFolder) {
            FolderPickerSheet { folder in
                entry.folder = folder
                services.store.updated([entry])
            }
        }
        .sheet(isPresented: $services.isExportPresented) {
            MacExportSheet(request: entry.previewRequest, name: entry.displayTitle)
        }
    }
}
