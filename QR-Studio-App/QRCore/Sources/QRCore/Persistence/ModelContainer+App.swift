import Foundation
import OSLog
import SwiftData

/// Configuration SwiftData commune aux quatre cibles et aux extensions.
public enum AppModelContainer {
    /// Groupe d'apps partagé avec l'extension de partage. À aligner sur les entitlements.
    public static let appGroupIdentifier = "group.app.qrstudio.shared"
    /// Conteneur CloudKit unique pour les quatre plateformes. À aligner sur les entitlements.
    public static let cloudKitContainerIdentifier = "iCloud.app.qrstudio"

    public static let schema = Schema([CodeEntry.self, CodeStyle.self, Folder.self, SearchSite.self])

    /// Crée le conteneur. La synchro iCloud peut être coupée par l'utilisateur :
    /// on passe alors à une configuration strictement locale.
    public static func make(cloudSync: Bool, inMemory: Bool = false) throws -> ModelContainer {
        let configuration: ModelConfiguration
        if inMemory {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        } else {
            configuration = ModelConfiguration(
                "QRStudio",
                schema: schema,
                groupContainer: sharedGroupContainer,
                cloudKitDatabase: cloudSync ? .private(cloudKitContainerIdentifier) : .none
            )
        }
        let container = try ModelContainer(for: schema, configurations: [configuration])
        Logger.persistence.info("Conteneur prêt, synchro iCloud : \(cloudSync && !inMemory)")
        return container
    }

    /// Utilise le groupe d'apps s'il est provisionné, sinon le dossier privé de l'app.
    private static var sharedGroupContainer: ModelConfiguration.GroupContainer {
        let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
        return url == nil ? .none : .identifier(appGroupIdentifier)
    }

    /// Installe les sites de recherche par défaut si aucun n'existe encore.
    @MainActor
    public static func seedDefaults(in context: ModelContext) {
        do {
            let count = try context.fetchCount(FetchDescriptor<SearchSite>())
            guard count == 0 else { return }
            for (index, site) in SearchSite.defaults.enumerated() {
                context.insert(SearchSite(name: site.name, urlTemplate: site.template, sortOrder: index, isBuiltIn: true))
            }
            try context.save()
        } catch {
            Logger.persistence.error("Sites par défaut non installés : \(error.localizedDescription)")
        }
    }

    /// Vide définitivement la corbeille des entrées supprimées depuis plus de 30 jours.
    @MainActor
    public static func purgeTrash(in context: ModelContext, now: Date = .now) {
        guard let limit = Calendar.current.date(byAdding: .day, value: -30, to: now) else { return }
        let never = Date.distantFuture
        do {
            let descriptor = FetchDescriptor<CodeEntry>(predicate: #Predicate { entry in
                (entry.deletedAt ?? never) < limit
            })
            for entry in try context.fetch(descriptor) {
                context.delete(entry)
            }
            try context.save()
        } catch {
            Logger.persistence.error("Purge de la corbeille impossible : \(error.localizedDescription)")
        }
    }
}
