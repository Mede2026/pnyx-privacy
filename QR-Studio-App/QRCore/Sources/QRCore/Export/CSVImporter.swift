import Foundation

/// Import CSV : colonnes contenu, type, libellé (en-têtes français ou anglais, ou par position).
public enum CSVImporter {
    public struct Row: Sendable, Equatable {
        public var content: String
        public var type: String
        public var label: String
    }

    public static func rows(from data: Data) -> [Row] {
        var text = String(decoding: data, as: UTF8.self)
        if text.hasPrefix("\u{FEFF}") { text.removeFirst() }
        let records = parse(text)
        guard let header = records.first else { return [] }
        let names = header.map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        func index(_ aliases: [String]) -> Int? { names.firstIndex { aliases.contains($0) } }
        let contentIndex = index(["contenu", "content"])
        let typeIndex = index(["type"])
        let labelIndex = index(["libellé", "libelle", "label"])
        let hasHeader = contentIndex != nil
        let body = hasHeader ? Array(records.dropFirst()) : records
        return body.compactMap { record in
            func field(_ i: Int?, _ fallback: Int) -> String {
                let position = i ?? (hasHeader ? -1 : fallback)
                return position >= 0 && position < record.count ? record[position] : ""
            }
            let content = field(contentIndex, 0)
            guard !content.isEmpty else { return nil }
            return Row(content: content, type: field(typeIndex, 1), label: field(labelIndex, 2))
        }
    }

    /// Analyseur RFC 4180 : guillemets, guillemets doublés, retours à la ligne dans un champ.
    static func parse(_ text: String) -> [[String]] {
        var records: [[String]] = []
        var record: [String] = []
        var field = ""
        var inQuotes = false
        var iterator = Array(text).makeIterator()
        var pending: Character? = iterator.next()
        while let character = pending {
            pending = iterator.next()
            if inQuotes {
                if character == "\"" {
                    if pending == "\"" {
                        field.append("\"")
                        pending = iterator.next()
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(character)
                }
            } else {
                switch character {
                case "\"": inQuotes = true
                case ",", ";": record.append(field); field = ""
                case "\n", "\r\n", "\r":
                    record.append(field); field = ""
                    if record.contains(where: { !$0.isEmpty }) { records.append(record) }
                    record = []
                default: field.append(character)
                }
            }
        }
        record.append(field)
        if record.contains(where: { !$0.isEmpty }) { records.append(record) }
        return records
    }
}
