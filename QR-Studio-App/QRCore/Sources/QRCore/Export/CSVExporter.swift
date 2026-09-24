import Foundation

/// CSV annoté : UTF-8 avec BOM (sinon Excel casse les accents), virgules, champs entre guillemets,
/// guillemets internes doublés. Colonnes : date, contenu, symbologie, type, libellé, quantité,
/// note, dossier, origine.
public enum CSVExporter {
    public static var headers: [String] {
        [L("date"), L("contenu"), L("symbologie"), L("type"), L("libellé"), L("quantité"), L("note"), L("dossier"), L("origine")]
    }

    public static func csv(_ rows: [ExportRow]) -> Data {
        var lines = [headers.map(quote).joined(separator: ",")]
        for row in rows {
            lines.append([
                timestamp(row.date), row.content, row.symbology, row.type, row.label,
                String(row.quantity), row.note, row.folder, row.origin
            ].map(quote).joined(separator: ","))
        }
        let text = lines.joined(separator: "\r\n") + "\r\n"
        return Data([0xEF, 0xBB, 0xBF]) + Data(text.utf8)
    }

    static func quote(_ field: String) -> String {
        "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// Date lisible par les tableurs, indépendante de la langue.
    static func timestamp(_ date: Date) -> String {
        let c = Calendar(identifier: .gregorian).dateComponents(in: .current, from: date)
        return String(format: "%04d-%02d-%02d %02d:%02d:%02d",
                      c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
    }
}
