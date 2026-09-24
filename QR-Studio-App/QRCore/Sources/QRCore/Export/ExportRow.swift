import Foundation

/// Ligne d'export, détachée des modèles SwiftData.
public struct ExportRow: Sendable, Hashable {
    public var date: Date
    public var content: String
    public var symbology: String
    public var type: String
    public var label: String
    public var quantity: Int
    public var note: String
    public var folder: String
    public var origin: String

    public init(date: Date, content: String, symbology: String, type: String, label: String,
                quantity: Int, note: String, folder: String, origin: String) {
        self.date = date
        self.content = content
        self.symbology = symbology
        self.type = type
        self.label = label
        self.quantity = quantity
        self.note = note
        self.folder = folder
        self.origin = origin
    }

    public init(_ entry: CodeEntry) {
        self.init(date: entry.createdAt, content: entry.rawValue, symbology: entry.symbologyKind.displayName,
                  type: entry.contentKind.title, label: entry.label, quantity: entry.quantity, note: entry.note,
                  folder: entry.folder?.name ?? "",
                  origin: entry.originKind == .scanned ? L("Scanné") : L("Créé"))
    }
}
