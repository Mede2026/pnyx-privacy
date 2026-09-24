import OSLog
import QRCore
import SwiftData
import SwiftUI
import WidgetKit

struct PrimaryCodeProvider: TimelineProvider {
    func placeholder(in context: Context) -> PrimaryCodeEntry {
        PrimaryCodeEntry(date: .now, title: String(localized: "Carte de fidélité"), image: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (PrimaryCodeEntry) -> Void) {
        Task { completion(await Self.load()) }
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<PrimaryCodeEntry>) -> Void) {
        Task {
            let entry = await Self.load()
            completion(Timeline(entries: [entry], policy: .after(.now.addingTimeInterval(3600))))
        }
    }

    /// Lecture locale de la base de la montre (le widget ne synchronise pas lui-même).
    @MainActor
    private static func load() async -> PrimaryCodeEntry {
        do {
            let container = try AppModelContainer.make(cloudSync: false)
            var descriptor = FetchDescriptor<CodeEntry>(predicate: #Predicate { $0.isPrimary && $0.deletedAt == nil })
            descriptor.fetchLimit = 1
            guard let primary = try container.mainContext.fetch(descriptor).first else {
                return PrimaryCodeEntry(date: .now, title: nil, image: nil)
            }
            // Mêmes règles que l'app : même format de code, rien au-delà de 300 octets.
            let request = WatchDisplay.isTooDense(primary.rawValue)
                ? nil
                : WatchDisplay.request(payload: primary.rawValue, symbology: primary.symbology, quietZone: 1)
            var image: Data?
            if let request {
                image = try await CodeRenderer.shared.drawing(for: request).pngData(width: 120)
            }
            return PrimaryCodeEntry(date: .now, title: primary.displayTitle, image: image)
        } catch {
            Logger.general.error("Complication : \(error.localizedDescription)")
            return PrimaryCodeEntry(date: .now, title: nil, image: nil)
        }
    }
}
