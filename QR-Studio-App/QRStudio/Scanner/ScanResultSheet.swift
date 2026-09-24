import QRCore
import SwiftData
import SwiftUI

/// Feuille qui monte après un scan : type détecté, fiche structurée, actions, favori, note.
/// L'entrée est déjà enregistrée dans l'historique quand la feuille apparaît.
struct ScanResultSheet: View {
    @Bindable var entry: CodeEntry
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var actions = ActionHandler()
    @State private var isChoosingFolder = false

    var body: some View {
        let parsed = ScannedContentParser.parse(entry.rawValue, symbology: entry.symbologyKind)
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header(parsed)
                    ContentDetailCard(parsed: parsed, actions: actions)
                    ContentActionsView(parsed: parsed, raw: entry.rawValue, actions: actions, entry: entry)
                    CardSection {
                        LabelField(entry: entry)
                        Divider()
                        TextField("Ajouter une note", text: $entry.note, axis: .vertical)
                            .lineLimit(1...4)
                            .onSubmit { services.store.updated([entry]) }
                        Divider()
                        Button {
                            isChoosingFolder = true
                        } label: {
                            LabeledContent {
                                Text(entry.folder?.name ?? String(localized: "Aucun"))
                            } label: {
                                Label("Dossier", systemImage: "folder")
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }
                .padding()
            }
            .background(Color.groupedBackground)
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        entry.isFavorite.toggle()
                        services.store.updated([entry])
                    } label: {
                        Image(systemName: entry.isFavorite ? "star.fill" : "star")
                    }
                    .accessibilityLabel(entry.isFavorite ? Text("Retirer des favoris") : Text("Ajouter aux favoris"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        services.store.updated([entry])
                        dismiss()
                    }
                }
            }
        }
        .sheetHeight(.mediumAndLarge)
        .presentationDragIndicator(.visible)
        .alertHost()
        .task(id: entry.id) {
            // Vérification Safe Browsing du lien scanné : l'avertissement passe avant tout.
            guard case .url(let url) = parsed,
                  case .unsafe(let threat) = await services.safeBrowsing.verdict(for: url) else { return }
            actions.warning = SafeBrowsingWarning(url: url, threat: threat)
        }
        .actionPresentations(actions)
        .sheet(isPresented: $isChoosingFolder) {
            FolderPickerSheet { folder in
                entry.folder = folder
                services.store.updated([entry])
            }
        }
        .onAppear {
            actions.alerts = services.alerts
            // Le résultat est annoncé automatiquement par VoiceOver.
            UIAccessibility.post(notification: .announcement,
                                 argument: "\(parsed.contentType.title). \(entry.summary)")
        }
        .onDisappear { services.store.updated([entry]) }
    }

    private func header(_ parsed: ParsedContent) -> some View {
        HStack(spacing: 12) {
            Image(systemName: parsed.contentType.symbolName)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 44, height: 44)
                .background(Color.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(parsed.contentType.title)
                    .font(.title3.bold())
                Text("\(entry.symbologyKind.displayName) · \(entry.createdAt.formatted(date: .omitted, time: .shortened))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
