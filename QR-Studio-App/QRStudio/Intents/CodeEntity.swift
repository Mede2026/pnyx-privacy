import AppIntents
import Foundation
import QRCore
import SwiftData

/// Un code enregistré, nommable par Siri et les Raccourcis : « Montre mon code Wi-Fi maison ».
struct CodeEntity: AppEntity, Identifiable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Code")
    static let defaultQuery = CodeEntityQuery()

    let id: UUID
    let title: String
    let content: String
    let typeTitle: String
    let thumbnail: Data?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(typeTitle) · \(String(content.prefix(60)))",
            image: thumbnail.map { .init(data: $0) } ?? .init(systemName: "qrcode")
        )
    }

    @MainActor
    init(_ entry: CodeEntry, thumbnail: Data? = nil) {
        id = entry.id
        title = entry.displayTitle
        content = entry.rawValue
        typeTitle = entry.contentKind.title
        self.thumbnail = thumbnail
    }
}
