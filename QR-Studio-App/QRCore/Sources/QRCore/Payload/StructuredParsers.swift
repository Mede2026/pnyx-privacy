import Foundation

/// Lecture des formats structurés : Wi-Fi, vCard, MECARD, MATMSG et VEVENT.
enum StructuredParsers {
    // MARK: - Champs « clé:valeur; » avec échappement par barre oblique inverse

    /// Découpe sur les « ; » non échappés, puis chaque champ sur le premier « : ».
    static func semicolonFields(_ body: Substring) -> [(String, String)] {
        var fields: [(String, String)] = []
        var current = ""
        var escaping = false
        func flush() {
            guard let colon = current.firstIndex(of: ":") else { current = ""; return }
            fields.append((String(current[..<colon]).uppercased(), String(current[current.index(after: colon)...])))
            current = ""
        }
        for character in body {
            if escaping {
                current.append(character)
                escaping = false
            } else if character == "\\" {
                escaping = true
            } else if character == ";" {
                flush()
            } else {
                current.append(character)
            }
        }
        flush()
        return fields
    }

    static func wifi(_ text: String) -> WiFiNetwork? {
        let fields = semicolonFields(text.dropFirst(5))
        var network = WiFiNetwork(ssid: "", password: "", security: "", hidden: false)
        for (key, value) in fields {
            switch key {
            case "S": network.ssid = value
            case "P": network.password = value
            case "T": network.security = value
            case "H": network.hidden = value.lowercased() == "true"
            case "U", "I": network.identity = value
            case "E": network.eapMethod = value
            default: break
            }
        }
        return network.ssid.isEmpty ? nil : network
    }

    static func meCard(_ text: String) -> ContactCard {
        var card = ContactCard()
        for (key, value) in semicolonFields(text.dropFirst(7)) {
            switch key {
            case "N":
                let parts = value.split(separator: ",", maxSplits: 1).map(String.init)
                card.lastName = parts.first ?? ""
                card.firstName = parts.count > 1 ? parts[1] : ""
            case "TEL": card.phones.append(value)
            case "EMAIL": card.emails.append(value)
            case "ADR": card.addresses.append(value)
            case "URL": card.urls.append(value)
            case "ORG": card.organization = value
            case "NOTE": card.note = value
            default: break
            }
        }
        return card
    }

    static func matmsg(_ text: String) -> EmailMessage {
        var message = EmailMessage(to: "", subject: "", body: "")
        for (key, value) in semicolonFields(text.dropFirst(7)) {
            switch key {
            case "TO": message.to = value
            case "SUB": message.subject = value
            case "BODY": message.body = value
            default: break
            }
        }
        return message
    }

    // MARK: - vCard et iCalendar (lignes « NOM;PARAMÈTRES:valeur »)

    struct ContentLine {
        var name: String
        var parameters: [String: String]
        var value: String
    }

    /// Déplie les lignes continuées (qui commencent par une espace ou une tabulation).
    static func contentLines(_ text: String) -> [ContentLine] {
        let unfolded = text
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n ", with: "")
            .replacingOccurrences(of: "\n\t", with: "")
        return unfolded.split(separator: "\n").compactMap { line in
            guard let colon = line.firstIndex(of: ":") else { return nil }
            let head = line[..<colon].split(separator: ";").map(String.init)
            guard var name = head.first?.uppercased() else { return nil }
            if let dot = name.lastIndex(of: ".") { name = String(name[name.index(after: dot)...]) }
            var parameters: [String: String] = [:]
            for parameter in head.dropFirst() {
                let kv = parameter.split(separator: "=", maxSplits: 1).map(String.init)
                parameters[kv[0].uppercased()] = kv.count > 1 ? kv[1] : ""
            }
            return ContentLine(name: name, parameters: parameters, value: String(line[line.index(after: colon)...]))
        }
    }

    static func unescape(_ text: String) -> String {
        var result = ""
        var escaping = false
        for character in text {
            if escaping {
                result.append(character == "n" || character == "N" ? "\n" : character)
                escaping = false
            } else if character == "\\" {
                escaping = true
            } else {
                result.append(character)
            }
        }
        return result
    }

    static func vCard(_ text: String) -> ContactCard {
        var card = ContactCard()
        for line in contentLines(text) {
            let value = unescape(line.value)
            switch line.name {
            case "FN": card.fullName = value
            case "N":
                let parts = line.value.split(separator: ";", omittingEmptySubsequences: false).map { unescape(String($0)) }
                card.lastName = parts.first ?? ""
                card.firstName = parts.count > 1 ? parts[1] : ""
            case "ORG": card.organization = value.replacingOccurrences(of: ";", with: ", ")
            case "TITLE": card.jobTitle = value
            case "TEL": card.phones.append(value)
            case "EMAIL": card.emails.append(value)
            case "URL": card.urls.append(value)
            case "NOTE": card.note = value
            case "ADR":
                let parts = line.value.split(separator: ";", omittingEmptySubsequences: false)
                    .map { unescape(String($0)).trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
                if !parts.isEmpty { card.addresses.append(parts.joined(separator: ", ")) }
            default: break
            }
        }
        return card
    }

    static func vEvent(_ text: String) -> CalendarEvent {
        var event = CalendarEvent()
        var inEvent = false
        for line in contentLines(text) {
            if line.name == "BEGIN", line.value.uppercased() == "VEVENT" { inEvent = true; continue }
            if line.name == "END", line.value.uppercased() == "VEVENT" { break }
            guard inEvent else { continue }
            switch line.name {
            case "SUMMARY": event.title = unescape(line.value)
            case "LOCATION": event.location = unescape(line.value)
            case "DESCRIPTION": event.notes = unescape(line.value)
            case "DTSTART":
                event.start = date(line.value, timeZone: line.parameters["TZID"])
                event.isAllDay = line.value.count == 8
            case "DTEND":
                event.end = date(line.value, timeZone: line.parameters["TZID"])
            default: break
            }
        }
        return event
    }

    /// Formats iCalendar : 20260919T140000Z (UTC), 20260919T140000 (heure locale ou TZID), 20260919 (journée).
    static func date(_ value: String, timeZone identifier: String?) -> Date? {
        let digits = value.filter(\.isNumber)
        guard digits.count == 8 || digits.count == 14 else { return nil }
        func number(_ from: Int, _ length: Int) -> Int? {
            let start = digits.index(digits.startIndex, offsetBy: from)
            return Int(digits[start..<digits.index(start, offsetBy: length)])
        }
        var components = DateComponents()
        components.year = number(0, 4)
        components.month = number(4, 2)
        components.day = number(6, 2)
        if digits.count == 14 {
            components.hour = number(8, 2)
            components.minute = number(10, 2)
            components.second = number(12, 2)
        }
        var calendar = Calendar(identifier: .gregorian)
        if value.hasSuffix("Z") {
            calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        } else if let identifier, let zone = TimeZone(identifier: identifier) {
            calendar.timeZone = zone
        } else {
            calendar.timeZone = .current
        }
        return calendar.date(from: components)
    }
}
