import OSLog
import QRCore
import SwiftUI
@preconcurrency import Translation

/// Traduction d'un lot entier en une fois (TranslationSession, iOS 18).
/// Le premier usage d'une paire de langues déclenche le téléchargement géré par le système.
@available(iOS 18.0, *)
struct BatchTranslationSheet: View {
    let entries: [CodeEntry]
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var configuration: TranslationSession.Configuration?
    @State private var translations: [UUID: String] = [:]
    @State private var failed = false

    var body: some View {
        NavigationStack {
            List(entries) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.rawValue).font(.subheadline).foregroundStyle(.secondary).lineLimit(3)
                    if let translated = translations[entry.id] {
                        Text(translated).font(.body)
                    } else if !failed {
                        ProgressView().frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .overlay {
                if failed {
                    ContentUnavailableView("Traduction impossible", systemImage: "translate",
                                           description: Text("La langue n’a pas pu être détectée ou téléchargée."))
                }
            }
            .navigationTitle("Traduire le lot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    // Rien n'est écrit sans cette demande explicite.
                    Button("Ajouter aux notes") {
                        saveToNotes()
                        dismiss()
                    }
                    .disabled(translations.isEmpty)
                }
            }
        }
        .onAppear { configuration = TranslationSession.Configuration() }
        .translationTask(configuration) { session in
            await translate(with: session)
        }
    }

    private func translate(with session: TranslationSession) async {
        let items = entries.map { (text: $0.rawValue, id: $0.id.uuidString) }
        do {
            for response in try await session.translations(from: Self.requests(for: items)) {
                guard let id = response.clientIdentifier.flatMap(UUID.init(uuidString:)) else { continue }
                translations[id] = response.targetText
            }
        } catch {
            Logger.general.error("Traduction du lot impossible : \(error.localizedDescription)")
            failed = true
        }
    }

    /// Construites hors de l'acteur principal : le tableau n'est lié à aucun état de la vue.
    nonisolated private static func requests(for items: [(text: String, id: String)]) -> [TranslationSession.Request] {
        items.map { TranslationSession.Request(sourceText: $0.text, clientIdentifier: $0.id) }
    }

    private func saveToNotes() {
        let changed = entries.filter { translations[$0.id] != nil }
        for entry in changed {
            guard let translated = translations[entry.id] else { continue }
            entry.note = entry.note.isEmpty ? translated : entry.note + "\n\n" + translated
        }
        services.store.updated(changed)
    }
}
