import AppIntents
import Foundation
import QRCore
import SwiftData

/// Requêtes de codes, servies par le même conteneur que l'app.
struct CodeEntityQuery: EntityStringQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [CodeEntity] {
        let context = AppServices.shared.container.mainContext
        let entries = try context.fetch(FetchDescriptor<CodeEntry>(predicate: #Predicate { identifiers.contains($0.id) }))
        return await Self.entities(entries)
    }

    /// Suggestions : favoris puis codes récents.
    @MainActor
    func suggestedEntities() async throws -> [CodeEntity] {
        let context = AppServices.shared.container.mainContext
        var favorites = FetchDescriptor<CodeEntry>(
            predicate: #Predicate { $0.deletedAt == nil && $0.isFavorite },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        favorites.fetchLimit = 10
        var recent = FetchDescriptor<CodeEntry>(
            predicate: #Predicate { $0.deletedAt == nil && !$0.isFavorite },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        recent.fetchLimit = 10
        return await Self.entities(try context.fetch(favorites) + context.fetch(recent))
    }

    @MainActor
    func entities(matching string: String) async throws -> [CodeEntity] {
        var criteria = HistoryPredicate.Criteria(
            origins: CodeEntry.Origin.allCases.map(\.rawValue),
            contentTypes: ContentType.allCases.map(\.rawValue),
            symbologies: Symbology.allCases.map(\.rawValue)
        )
        criteria.text = string
        var descriptor = FetchDescriptor<CodeEntry>(predicate: HistoryPredicate.make(criteria),
                                                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = 20
        return await Self.entities(try AppServices.shared.container.mainContext.fetch(descriptor))
    }

    @MainActor
    private static func entities(_ entries: [CodeEntry]) async -> [CodeEntity] {
        var result: [CodeEntity] = []
        for entry in entries {
            let data = await ThumbnailCache.shared.cachedImageData(id: entry.id, request: entry.renderRequest)
            result.append(CodeEntity(entry, thumbnail: data))
        }
        return result
    }
}
