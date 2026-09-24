import Foundation
import QRCore
import SwiftData

/// Critères cumulables de l'historique. Tout est appliqué en base, dans le FetchDescriptor,
/// jamais par un filtre Swift sur un tableau complet.
struct HistoryFilter: Equatable {
    enum Sort: String, CaseIterable, Identifiable {
        case newest, oldest, alphabetical
        var id: String { rawValue }

        var title: LocalizedStringResource {
            switch self {
            case .newest: "Plus récent"
            case .oldest: "Plus ancien"
            case .alphabetical: "Alphabétique"
            }
        }
    }

    var searchText = ""
    var origin: CodeEntry.Origin?
    var contentType: ContentType?
    var symbology: Symbology?
    var favoritesOnly = false
    var folderID: UUID?
    var startDate: Date?
    var endDate: Date?
    var inTrash = false
    var sort: Sort = .newest

    init() {}


    /// Nombre de critères actifs, hors recherche et tri, pour le badge du bouton Filtres.
    var activeCount: Int {
        [origin != nil, contentType != nil, symbology != nil, favoritesOnly, folderID != nil,
         startDate != nil || endDate != nil].count { $0 }
    }

    func descriptor(offset: Int = 0, limit: Int? = nil) -> FetchDescriptor<CodeEntry> {
        var descriptor = FetchDescriptor<CodeEntry>(predicate: predicate, sortBy: sortDescriptors)
        descriptor.fetchOffset = offset
        if let limit { descriptor.fetchLimit = limit }
        descriptor.relationshipKeyPathsForPrefetching = [\.style]
        return descriptor
    }

    private var sortDescriptors: [SortDescriptor<CodeEntry>] {
        switch sort {
        case .newest: [SortDescriptor(\.createdAt, order: .reverse)]
        case .oldest: [SortDescriptor(\.createdAt, order: .forward)]
        case .alphabetical: [SortDescriptor(\.label), SortDescriptor(\.rawValue)]
        }
    }

    private var predicate: Predicate<CodeEntry> {
        var criteria = HistoryPredicate.Criteria(
            origins: origin.map { [$0.rawValue] } ?? CodeEntry.Origin.allCases.map(\.rawValue),
            contentTypes: contentType.map { [$0.rawValue] } ?? ContentType.allCases.map(\.rawValue),
            symbologies: symbology.map { [$0.rawValue] } ?? Symbology.allCases.map(\.rawValue)
        )
        criteria.inTrash = inTrash
        criteria.favoritesOnly = favoritesOnly
        criteria.folderID = folderID
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        criteria.text = text.isEmpty ? nil : text
        if let startDate { criteria.from = Calendar.current.startOfDay(for: startDate) }
        if let endDate, let next = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: endDate)) {
            criteria.to = next
        }
        return HistoryPredicate.make(criteria)
    }
}
