import QRCore
import SwiftData
import SwiftUI

/// Code principal, favoris et codes récents.
struct WatchCodeListView: View {
    @Query(filter: #Predicate<CodeEntry> { $0.deletedAt == nil && $0.isPrimary }) private var primary: [CodeEntry]
    @Query(filter: #Predicate<CodeEntry> { $0.deletedAt == nil && $0.isFavorite },
           sort: \CodeEntry.createdAt, order: .reverse) private var favorites: [CodeEntry]
    @Query(Self.recentDescriptor) private var recent: [CodeEntry]
    @State private var path: [UUID] = []

    private static var recentDescriptor: FetchDescriptor<CodeEntry> {
        var descriptor = FetchDescriptor<CodeEntry>(predicate: #Predicate { $0.deletedAt == nil && !$0.isFavorite },
                                                    sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        descriptor.fetchLimit = 15
        return descriptor
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if let main = primary.first {
                    Section("Code principal") { row(main) }
                }
                if !favorites.isEmpty {
                    Section("Favoris") {
                        ForEach(favorites) { row($0) }
                    }
                }
                if !recent.isEmpty {
                    Section("Récents") {
                        ForEach(recent) { row($0) }
                    }
                }
            }
            .overlay {
                if primary.isEmpty && favorites.isEmpty && recent.isEmpty {
                    ContentUnavailableView("Aucun code", systemImage: "qrcode",
                                           description: Text("Les codes enregistrés sur l’iPhone apparaissent ici."))
                }
            }
            .navigationTitle("QR Studio")
            .navigationDestination(for: UUID.self) { id in
                WatchCodeDisplayView(entryID: id)
            }
        }
        #if DEBUG
        // Vérification dans le simulateur : « -QRStudioOpenPrimary » ouvre le code principal au lancement.
        .onChange(of: primary.first?.id, initial: true) { _, id in
            if let id, ProcessInfo.processInfo.arguments.contains("-QRStudioOpenPrimary") { path = [id] }
        }
        #endif
        .onOpenURL { url in
            // qrstudio://code/<UUID>, depuis la complication.
            if url.host() == "code", let id = UUID(uuidString: url.lastPathComponent) {
                path = [id]
            } else if url.host() == "primary", let main = primary.first {
                path = [main.id]
            }
        }
    }

    private func row(_ entry: CodeEntry) -> some View {
        NavigationLink(value: entry.id) {
            Label {
                VStack(alignment: .leading) {
                    Text(entry.displayTitle).lineLimit(1)
                    Text(entry.summary).font(.footnote).foregroundStyle(.secondary).lineLimit(1)
                }
            } icon: {
                Image(systemName: entry.contentKind.symbolName)
            }
        }
    }
}
