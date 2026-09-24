import OSLog
import QRCore
import SwiftData
import SwiftUI
import WidgetKit

struct MainCodeProvider: TimelineProvider {
    func placeholder(in context: Context) -> MainCodeEntry {
        MainCodeEntry(date: .now, id: nil, title: String(localized: "Carte de fidélité"), image: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (MainCodeEntry) -> Void) {
        Task { completion(await Self.load()) }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<MainCodeEntry>) -> Void) {
        Task {
            let entry = await Self.load()
            completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600))))
        }
    }

    /// Lecture de la base commune (groupe d'apps) ; le widget ne synchronise pas lui-même.
    @MainActor
    private static func load() async -> MainCodeEntry {
        do {
            let container = try AppModelContainer.make(cloudSync: false)
            var descriptor = FetchDescriptor<CodeEntry>(predicate: #Predicate { $0.isPrimary && $0.deletedAt == nil })
            descriptor.fetchLimit = 1
            if try container.mainContext.fetch(descriptor).isEmpty {
                // Sans code principal, on montre le dernier favori.
                descriptor = FetchDescriptor<CodeEntry>(predicate: #Predicate { $0.isFavorite && $0.deletedAt == nil },
                                                        sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
                descriptor.fetchLimit = 1
            }
            guard let entry = try container.mainContext.fetch(descriptor).first else {
                return MainCodeEntry(date: .now, id: nil, title: nil, image: nil)
            }
            let symbology = entry.symbologyKind.isGeneratable ? entry.symbologyKind : .qr
            let request = RenderRequest(payload: entry.rawValue, symbology: symbology,
                                        style: entry.style?.config ?? StyleConfig())
            let image = try await CodeRenderer.shared.drawing(for: request).pngData(width: 360)
            return MainCodeEntry(date: .now, id: entry.id, title: entry.displayTitle, image: image)
        } catch {
            Logger.general.error("Widget : \(error.localizedDescription)")
            return MainCodeEntry(date: .now, id: nil, title: nil, image: nil)
        }
    }
}
