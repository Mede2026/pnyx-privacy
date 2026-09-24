import Foundation
import Observation
import OSLog
import QRCore
import SwiftData

/// Pagination de l'historique : 50 entrées à la fois, la page suivante quand la rangée
/// à 10 éléments de la fin apparaît. Un @Query sans limite chargerait toute la base.
@MainActor
@Observable
final class HistoryListModel {
    static let pageSize = 50

    private(set) var entries: [CodeEntry] = []
    private(set) var hasMore = true
    private(set) var totalCount = 0
    var filter = HistoryFilter()

    struct DaySection: Identifiable {
        let id: Date
        let entries: [CodeEntry]
    }

    /// Regroupement par jour, calculé sur la page chargée seulement.
    var sections: [DaySection] {
        guard filter.sort != .alphabetical else {
            return entries.isEmpty ? [] : [DaySection(id: .distantPast, entries: entries)]
        }
        let calendar = Calendar.current
        var result: [DaySection] = []
        for entry in entries {
            let day = calendar.startOfDay(for: entry.createdAt)
            if let last = result.last, last.id == day {
                result[result.count - 1] = DaySection(id: day, entries: last.entries + [entry])
            } else {
                result.append(DaySection(id: day, entries: [entry]))
            }
        }
        return result
    }

    func reload(in context: ModelContext) {
        let keep = max(entries.count, Self.pageSize)
        do {
            entries = try context.fetch(filter.descriptor(offset: 0, limit: keep))
            totalCount = try context.fetchCount(filter.descriptor())
            hasMore = entries.count < totalCount
        } catch {
            Logger.persistence.error("Historique illisible : \(error.localizedDescription)")
            entries = []
            hasMore = false
        }
    }

    func reset(in context: ModelContext) {
        entries = []
        hasMore = true
        reload(in: context)
    }

    func loadMoreIfNeeded(current entry: CodeEntry, in context: ModelContext) {
        guard hasMore, let index = entries.firstIndex(where: { $0.id == entry.id }),
              index >= entries.count - 10 else { return }
        do {
            let page = try context.fetch(filter.descriptor(offset: entries.count, limit: Self.pageSize))
            entries += page
            hasMore = page.count == Self.pageSize
        } catch {
            Logger.persistence.error("Page suivante illisible : \(error.localizedDescription)")
            hasMore = false
        }
    }

    func remove(_ removed: [CodeEntry]) {
        let ids = Set(removed.map(\.id))
        entries.removeAll { ids.contains($0.id) }
        totalCount -= ids.count
    }
}
