import Foundation

/// Fichier de sauvegarde manuelle, indépendant d'Apple. `schemaVersion` en tête permet
/// aux versions futures de lire les anciens fichiers. Les logos sont en base64 (Data encodée par JSONEncoder).
public struct BackupDocument: Codable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var exportedAt: Date
    public var app: String
    public var entries: [EntryRecord]
    public var folders: [FolderRecord]
    public var presets: [StyleRecord]
    public var searchSites: [SearchSiteRecord]

    public struct EntryRecord: Codable, Sendable {
        public var id: UUID
        public var rawValue: String
        public var symbology: String
        public var contentType: String
        public var origin: String
        public var createdAt: Date
        public var isFavorite: Bool
        public var note: String
        public var label: String
        public var latitude: Double?
        public var longitude: Double?
        public var quantity: Int
        public var deletedAt: Date?
        public var isPrimary: Bool
        public var productCode: String?
        public var placeName: String?
        public var folderID: UUID?
        public var style: StyleRecord?
    }

    public struct StyleRecord: Codable, Sendable {
        public var id: UUID
        public var config: StyleConfig
        public var isUserPreset: Bool
        public var presetName: String
        public var createdAt: Date
    }

    public struct FolderRecord: Codable, Sendable {
        public var id: UUID
        public var name: String
        public var symbolName: String
        public var colorHex: String
        public var createdAt: Date
    }

    public struct SearchSiteRecord: Codable, Sendable {
        public var id: UUID
        public var name: String
        public var urlTemplate: String
        public var sortOrder: Int
        public var isEnabled: Bool
        public var isBuiltIn: Bool
    }
}
