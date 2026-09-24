import Foundation
import SwiftData

@Model
public final class Folder {
    public var id: UUID = UUID()
    public var name: String = ""
    public var symbolName: String = "folder"
    public var colorHex: String = "#007AFF"
    public var createdAt: Date = Date()
    public var entries: [CodeEntry]? = []

    public init(name: String, symbolName: String = "folder", colorHex: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.symbolName = symbolName
        self.colorHex = colorHex
        self.createdAt = .now
    }

    /// Nombre d'entrées actives (hors corbeille).
    public var activeCount: Int {
        (entries ?? []).count { $0.deletedAt == nil }
    }
}
