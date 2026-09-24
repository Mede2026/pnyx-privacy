import Foundation
import QRCore

/// Import CSV (colonnes contenu, type, libellé), partagé par les réglages et le menu Fichier du Mac.
@MainActor
enum CSVImport {
    /// Renvoie le nombre de codes importés.
    static func run(_ data: Data, into store: EntryStore) -> Int {
        let rows = CSVImporter.rows(from: data)
        for row in rows {
            let parsed = ScannedContentParser.parse(row.content)
            let type = ContentType.allCases.first { $0.rawValue == row.type || $0.title == row.type } ?? parsed.contentType
            let symbology: Symbology = type == .product ? .ean13 : .qr
            _ = store.recordGenerated(payload: row.content, symbology: symbology, contentType: type, style: nil, label: row.label)
        }
        return rows.count
    }
}
