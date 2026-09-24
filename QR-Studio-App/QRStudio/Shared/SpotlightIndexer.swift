import CoreSpotlight
import Foundation
import OSLog
import QRCore
import SwiftData
import UniformTypeIdentifiers

/// Indexation CoreSpotlight : chaque code est retrouvable depuis la recherche de l'écran d'accueil.
/// Désindexé à la suppression (ou à la mise en corbeille), sinon des résultats fantômes persistent.
@MainActor
final class SpotlightIndexer {
    static let domain = "app.qrstudio.codes"
    /// Version 2 : contenu sans mot de passe Wi-Fi.
    private static let indexVersion = 2
    private static let lastIndexedKey = "spotlightLastIndexedDate"
    private let index = CSSearchableIndex.default()

    func update(_ entries: [CodeEntry], kind: EntryStore.ChangeKind) {
        let active = entries.filter { $0.deletedAt == nil && kind == .upserted }
        let removedIDs = entries.filter { $0.deletedAt != nil || kind == .removed }.map(\.id.uuidString)
        if !removedIDs.isEmpty {
            index.deleteSearchableItems(withIdentifiers: removedIDs) { error in
                if let error { Logger.general.error("Désindexation impossible : \(error.localizedDescription)") }
            }
        }
        guard !active.isEmpty else { return }
        let snapshots = active.map(Snapshot.init)
        Task { await Self.index(snapshots) }
    }

    /// Réindexe tout au premier lancement d'une nouvelle version du format d'index.
    func reindexIfNeeded(context: ModelContext) {
        let key = "spotlightIndexVersion"
        guard UserDefaults.standard.integer(forKey: key) < Self.indexVersion else { return }
        do {
            let descriptor = FetchDescriptor<CodeEntry>(predicate: #Predicate { $0.deletedAt == nil })
            let snapshots = try context.fetch(descriptor).map(Snapshot.init)
            Task {
                await Self.index(snapshots)
                UserDefaults.standard.set(Self.indexVersion, forKey: key)
                UserDefaults.standard.set(Date.now, forKey: Self.lastIndexedKey)
            }
        } catch {
            Logger.general.error("Réindexation impossible : \(error.localizedDescription)")
        }
    }

    /// Codes écrits hors de l'app (extension de partage, autre appareil via iCloud) depuis la dernière indexation.
    func indexNewEntries(context: ModelContext) {
        let since = UserDefaults.standard.object(forKey: Self.lastIndexedKey) as? Date ?? .distantPast
        let now = Date.now
        do {
            let descriptor = FetchDescriptor<CodeEntry>(predicate: #Predicate { $0.deletedAt == nil && $0.createdAt > since })
            let snapshots = try context.fetch(descriptor).map(Snapshot.init)
            UserDefaults.standard.set(now, forKey: Self.lastIndexedKey)
            guard !snapshots.isEmpty else { return }
            Task { await Self.index(snapshots) }
        } catch {
            Logger.general.error("Indexation des nouveaux codes impossible : \(error.localizedDescription)")
        }
    }

    /// Valeur détachée de SwiftData, transmissible hors du fil principal.
    struct Snapshot: Sendable {
        let id: UUID
        let title: String
        let content: String
        let typeTitle: String
        let request: RenderRequest

        init(_ entry: CodeEntry) {
            id = entry.id
            title = entry.label.isEmpty ? entry.contentKind.title : entry.label
            // Un mot de passe Wi-Fi n'a rien à faire dans l'index de recherche du système.
            content = String(SecretRedactor.redacted(entry.rawValue).prefix(500))
            typeTitle = entry.contentKind.title
            request = entry.renderRequest
        }
    }

    private static func index(_ snapshots: [Snapshot]) async {
        var items: [CSSearchableItem] = []
        for snapshot in snapshots {
            let attributes = CSSearchableItemAttributeSet(contentType: .content)
            attributes.title = snapshot.title
            attributes.contentDescription = snapshot.content
            attributes.keywords = [snapshot.typeTitle, "QR", "code"]
            attributes.thumbnailData = await ThumbnailCache.shared.image(id: snapshot.id, request: snapshot.request)?.pngData()
            items.append(CSSearchableItem(uniqueIdentifier: snapshot.id.uuidString, domainIdentifier: domain,
                                          attributeSet: attributes))
        }
        do {
            try await CSSearchableIndex.default().indexSearchableItems(items)
        } catch {
            Logger.general.error("Indexation Spotlight impossible : \(error.localizedDescription)")
        }
    }

    /// Identifiant de l'entrée ouverte depuis un résultat Spotlight.
    static func entryID(from activity: NSUserActivity) -> UUID? {
        (activity.userInfo?[CSSearchableItemActivityIdentifier] as? String).flatMap(UUID.init(uuidString:))
    }
}
