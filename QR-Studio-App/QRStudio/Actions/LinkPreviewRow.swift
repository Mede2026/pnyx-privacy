@preconcurrency import LinkPresentation
import QRCore
import SwiftUI

/// Titre de la page et vraie destination d'un lien (utile pour les liens raccourcis).
/// Le site n'est contacté que sur demande, ou automatiquement si « Aperçus en ligne » est activé,
/// et jamais pour un lien signalé par Safe Browsing.
struct LinkPreviewRow: View {
    let url: URL
    @Environment(AppSettings.self) private var settings
    @State private var state: PreviewState = .idle
    @State private var isTranslating = false

    enum PreviewState: Equatable {
        case idle, loading, blocked
        case found(title: String?, destination: String?)
        case failed
    }

    var body: some View {
        Group {
            switch state {
            case .idle:
                Button("Afficher le titre de la page", systemImage: "text.below.photo") {
                    Task { await load() }
                }
                .font(.callout)
            case .loading:
                ProgressView().frame(maxWidth: .infinity, alignment: .leading)
            case .blocked:
                EmptyView()
            case .found(let title, let destination):
                VStack(alignment: .leading, spacing: 4) {
                    if let title {
                        Text(title).font(.headline).lineLimit(3).textSelection(.enabled)
                        if ContentActionsView.needsTranslation(title) {
                            Button("Traduire le titre", systemImage: "translate") { isTranslating = true }
                                .font(.footnote)
                                .modifier(TranslationSheet(isPresented: $isTranslating, text: title))
                        }
                    }
                    if let destination {
                        Label("Mène en réalité à \(destination)", systemImage: "arrow.turn.down.right")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
            case .failed:
                Text("Aperçu indisponible pour ce lien.").font(.footnote).foregroundStyle(.secondary)
            }
        }
        .task(id: url) {
            state = .idle
            if settings.linkPreviews { await load() }
        }
    }

    private var isWebLink: Bool {
        ["http", "https"].contains(url.scheme?.lowercased() ?? "")
    }

    private func load() async {
        guard isWebLink else {
            state = .blocked
            return
        }
        state = .loading
        if case .unsafe = await AppServices.shared.safeBrowsing.verdict(for: url) {
            state = .blocked
            return
        }
        let provider = LPMetadataProvider()
        provider.shouldFetchSubresources = false
        provider.timeout = 8
        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            let title = metadata.title?.trimmingCharacters(in: .whitespacesAndNewlines)
            state = .found(title: title?.isEmpty == false ? title : nil, destination: destination(of: metadata))
        } catch {
            state = .failed
        }
    }

    /// Domaine final s'il diffère de celui affiché (redirection).
    private func destination(of metadata: LPLinkMetadata) -> String? {
        guard let final = metadata.url?.host(percentEncoded: false)?.lowercased(),
              let original = url.host(percentEncoded: false)?.lowercased() else { return nil }
        let strip: (String) -> String = { $0.hasPrefix("www.") ? String($0.dropFirst(4)) : $0 }
        return strip(final) == strip(original) ? nil : final
    }
}
