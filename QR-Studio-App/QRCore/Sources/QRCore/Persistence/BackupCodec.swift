import Foundation
import SwiftData

/// Export et réimport complets de la base. L'import écrit dans le même conteneur que le reste :
/// il se propage donc à iCloud et aux autres appareils.
@MainActor
public enum BackupCodec {
    public enum ImportMode: Sendable {
        /// Les entrées dont l'UUID existe déjà sont ignorées, les autres ajoutées.
        case merge
        /// La base locale est vidée, puis reconstruite depuis le fichier.
        case replace
    }

    public struct Summary: Sendable, Equatable {
        public var added: Int
        public var skipped: Int
        public var removed: Int
    }

    public static func export(from context: ModelContext) throws -> Data {
        let entries = try context.fetch(FetchDescriptor<CodeEntry>(sortBy: [SortDescriptor(\.createdAt)]))
        let folders = try context.fetch(FetchDescriptor<Folder>())
        let presets = try context.fetch(FetchDescriptor<CodeStyle>(predicate: #Predicate { $0.isUserPreset }))
        let sites = try context.fetch(FetchDescriptor<SearchSite>(sortBy: [SortDescriptor(\.sortOrder)]))
        return try encode(document(entries: entries, folders: folders, presets: presets, sites: sites))
    }

    /// Export JSON d'une sélection ou d'un dossier : même format que la sauvegarde,
    /// donc réimportable par « Fusionner ». Seuls les dossiers de ces codes sont inclus.
    public static func export(entries: [CodeEntry]) throws -> Data {
        var folders: [UUID: Folder] = [:]
        for folder in entries.compactMap(\.folder) { folders[folder.id] = folder }
        let sorted = entries.sorted { $0.createdAt < $1.createdAt }
        return try encode(document(entries: sorted, folders: Array(folders.values), presets: [], sites: []))
    }

    private static func document(entries: [CodeEntry], folders: [Folder], presets: [CodeStyle],
                                 sites: [SearchSite]) -> BackupDocument {
        BackupDocument(
            schemaVersion: BackupDocument.currentSchemaVersion,
            exportedAt: .now,
            app: "QR Studio",
            entries: entries.map { entry in
                BackupDocument.EntryRecord(
                    id: entry.id, rawValue: entry.rawValue, symbology: entry.symbology, contentType: entry.contentType,
                    origin: entry.origin, createdAt: entry.createdAt, isFavorite: entry.isFavorite, note: entry.note,
                    label: entry.label, latitude: entry.latitude, longitude: entry.longitude, quantity: entry.quantity,
                    deletedAt: entry.deletedAt, isPrimary: entry.isPrimary, productCode: entry.productCode,
                    placeName: entry.placeName, folderID: entry.folder?.id, style: entry.style.map(record)
                )
            },
            folders: folders.map {
                BackupDocument.FolderRecord(id: $0.id, name: $0.name, symbolName: $0.symbolName,
                                            colorHex: $0.colorHex, createdAt: $0.createdAt)
            },
            presets: presets.map(record),
            searchSites: sites.map {
                BackupDocument.SearchSiteRecord(id: $0.id, name: $0.name, urlTemplate: $0.urlTemplate,
                                                sortOrder: $0.sortOrder, isEnabled: $0.isEnabled, isBuiltIn: $0.isBuiltIn)
            }
        )
    }

    private static func encode(_ document: BackupDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(document)
    }

    public nonisolated static func decode(_ data: Data) throws -> BackupDocument {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let document: BackupDocument
        do {
            document = try decoder.decode(BackupDocument.self, from: data)
        } catch {
            throw BackupError.unreadable
        }
        guard document.schemaVersion <= BackupDocument.currentSchemaVersion else {
            throw BackupError.unsupportedVersion(document.schemaVersion)
        }
        return document
    }

    /// Nombre d'entrées qui seraient perdues par un remplacement, à afficher en clair.
    public static func entryCount(in context: ModelContext) throws -> Int {
        try context.fetchCount(FetchDescriptor<CodeEntry>())
    }

    @discardableResult
    public static func restore(_ document: BackupDocument, into context: ModelContext, mode: ImportMode) throws -> Summary {
        var removed = 0
        if mode == .replace {
            removed = try context.fetchCount(FetchDescriptor<CodeEntry>())
            try context.delete(model: CodeEntry.self)
            try context.delete(model: CodeStyle.self)
            try context.delete(model: Folder.self)
            try context.delete(model: SearchSite.self)
        }

        var folders: [UUID: Folder] = [:]
        for folder in try context.fetch(FetchDescriptor<Folder>()) { folders[folder.id] = folder }
        for record in document.folders where folders[record.id] == nil {
            let folder = Folder(name: record.name, symbolName: record.symbolName, colorHex: record.colorHex)
            folder.id = record.id
            folder.createdAt = record.createdAt
            context.insert(folder)
            folders[record.id] = folder
        }

        let existingIDs = Set(try context.fetch(FetchDescriptor<CodeEntry>()).map(\.id))
        var added = 0
        var skipped = 0
        for record in document.entries {
            guard !existingIDs.contains(record.id) else {
                skipped += 1
                continue
            }
            let entry = CodeEntry(rawValue: record.rawValue, symbology: Symbology(storedValue: record.symbology),
                                  contentType: ContentType(storedValue: record.contentType),
                                  origin: CodeEntry.Origin(rawValue: record.origin) ?? .scanned, createdAt: record.createdAt)
            entry.id = record.id
            entry.symbology = record.symbology
            entry.isFavorite = record.isFavorite
            entry.note = record.note
            entry.label = record.label
            entry.latitude = record.latitude
            entry.longitude = record.longitude
            entry.quantity = record.quantity
            entry.deletedAt = record.deletedAt
            entry.isPrimary = record.isPrimary
            entry.productCode = record.productCode
            entry.placeName = record.placeName
            entry.folder = record.folderID.flatMap { folders[$0] }
            entry.style = record.style.map(style)
            context.insert(entry)
            added += 1
        }

        let presetIDs = Set(try context.fetch(FetchDescriptor<CodeStyle>()).map(\.id))
        for record in document.presets where !presetIDs.contains(record.id) {
            context.insert(style(record))
        }

        let siteIDs = Set(try context.fetch(FetchDescriptor<SearchSite>()).map(\.id))
        for record in document.searchSites where !siteIDs.contains(record.id) {
            let site = SearchSite(name: record.name, urlTemplate: record.urlTemplate, sortOrder: record.sortOrder,
                                  isBuiltIn: record.isBuiltIn)
            site.id = record.id
            site.isEnabled = record.isEnabled
            context.insert(site)
        }

        try context.save()
        return Summary(added: added, skipped: skipped, removed: removed)
    }

    private static func record(_ style: CodeStyle) -> BackupDocument.StyleRecord {
        BackupDocument.StyleRecord(id: style.id, config: style.config, isUserPreset: style.isUserPreset,
                                   presetName: style.presetName, createdAt: style.createdAt)
    }

    private static func style(_ record: BackupDocument.StyleRecord) -> CodeStyle {
        let style = CodeStyle(config: record.config)
        style.id = record.id
        style.isUserPreset = record.isUserPreset
        style.presetName = record.presetName
        style.createdAt = record.createdAt
        return style
    }
}
