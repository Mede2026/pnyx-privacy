import QRCore
import SwiftData
import SwiftUI

/// Suggestion de libellé et de dossier, calculée sur l'appareil à l'ouverture de la feuille.
/// Le libellé est prérempli seulement si le champ est vide, signalé comme suggestion, et s'efface d'un geste.
/// Le dossier n'est jamais appliqué sans toucher « Ranger ».
struct LabelSuggestionRow: View {
    @Bindable var entry: CodeEntry
    @Environment(AppSettings.self) private var settings
    @Environment(AppServices.self) private var services
    @Query(sort: \Folder.name) private var folders: [Folder]
    @State private var suggestedLabel: String?
    @State private var suggestedFolder: Folder?
    @State private var isWorking = false

    var body: some View {
        if settings.suggestsLabels && OnDeviceIntelligence.isAvailable {
            VStack(alignment: .leading, spacing: 8) {
                if isWorking {
                    Label("Suggestion en cours…", systemImage: "apple.intelligence")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let suggestedLabel, entry.label == suggestedLabel {
                    HStack {
                        Label("Libellé suggéré par Apple Intelligence", systemImage: "apple.intelligence")
                        Spacer()
                        Button("Effacer") {
                            entry.label = ""
                            self.suggestedLabel = nil
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                if let folder = suggestedFolder, entry.folder == nil {
                    Button {
                        entry.folder = folder
                        services.store.updated([entry])
                        suggestedFolder = nil
                    } label: {
                        Label("Ranger dans « \(folder.name) »", systemImage: "folder")
                            .frame(maxWidth: .infinity)
                    }
                    .glassButtonStyle()
                }
            }
            .task(id: entry.id) { await suggest() }
        }
    }

    private func suggest() async {
        guard entry.label.isEmpty || entry.folder == nil else { return }
        isWorking = true
        let result = await OnDeviceIntelligence.suggestLabel(
            for: entry.rawValue, type: entry.contentKind, folders: folders.map(\.name))
        isWorking = false
        guard let result else { return }
        if entry.label.isEmpty, !result.label.isEmpty {
            entry.label = result.label
            suggestedLabel = result.label
        }
        suggestedFolder = result.folder.flatMap { name in folders.first { $0.name == name } }
    }
}
