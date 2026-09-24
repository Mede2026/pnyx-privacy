import Foundation

/// Formats structurés : Wi-Fi, vCard 3.0 et VEVENT.
enum PayloadFormats {
    /// WIFI:T:WPA;S:MonReseau;P:motdepasse;H:false;;
    /// Les caractères \ ; , : " sont échappés par une barre oblique inverse.
    static func wifi(_ input: WiFiInput) throws -> String {
        guard !input.ssid.isEmpty else { throw PayloadError.empty }
        var result = "WIFI:T:\(input.security.rawValue);S:\(escapeWiFi(input.ssid));"
        if input.security != .none {
            guard !input.password.isEmpty else { throw PayloadError.empty }
            result += "P:\(escapeWiFi(input.password));"
        }
        result += "H:\(input.hidden ? "true" : "false");;"
        return result
    }

    /// WIFI:T:WPA2-EAP;S:…;U:…;P:…;E:PEAP;;
    static func enterpriseWiFi(_ input: EnterpriseWiFiInput) throws -> String {
        guard !input.ssid.isEmpty, !input.identity.isEmpty else { throw PayloadError.empty }
        return "WIFI:T:WPA2-EAP;S:\(escapeWiFi(input.ssid));U:\(escapeWiFi(input.identity));"
            + "P:\(escapeWiFi(input.password));E:\(input.eap.rawValue);;"
    }

    static func escapeWiFi(_ text: String) -> String {
        var result = ""
        for character in text {
            if "\\;,:\"".contains(character) { result.append("\\") }
            result.append(character)
        }
        return result
    }

    /// vCard 3.0 complète (RFC 2426), lignes terminées par CRLF.
    static func vCard(_ c: ContactInput) throws -> String {
        let first = c.firstName.trimmingCharacters(in: .whitespaces)
        let last = c.lastName.trimmingCharacters(in: .whitespaces)
        let organization = c.organization.trimmingCharacters(in: .whitespaces)
        guard !(first.isEmpty && last.isEmpty && organization.isEmpty) else { throw PayloadError.empty }

        var lines = ["BEGIN:VCARD", "VERSION:3.0"]
        lines.append("N:\(escapeText(last));\(escapeText(first));;;")
        let fullName = [first, last].filter { !$0.isEmpty }.joined(separator: " ")
        lines.append("FN:\(escapeText(fullName.isEmpty ? organization : fullName))")
        if !organization.isEmpty { lines.append("ORG:\(escapeText(organization))") }
        if !c.phone.isEmpty { lines.append("TEL;TYPE=CELL:\(try PayloadBuilder.phoneNumber(c.phone))") }
        if !c.email.isEmpty {
            guard PayloadBuilder.isEmailAddress(c.email) else { throw PayloadError.invalidEmail }
            lines.append("EMAIL;TYPE=INTERNET:\(c.email)")
        }
        let address = [c.street, c.city, c.region, c.postalCode, c.country]
        if address.contains(where: { !$0.isEmpty }) {
            // ADR : boîte postale ; adresse étendue ; rue ; ville ; région ; code postal ; pays
            lines.append("ADR;TYPE=WORK:;;" + address.map(escapeText).joined(separator: ";"))
        }
        if !c.website.isEmpty { lines.append("URL:\(try PayloadBuilder.url(c.website))") }
        lines.append("END:VCARD")
        return lines.joined(separator: "\r\n")
    }

    /// BEGIN:VEVENT … END:VEVENT, dates en UTC au format yyyyMMdd'T'HHmmss'Z'.
    static func vEvent(_ e: EventInput) throws -> String {
        let title = e.title.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { throw PayloadError.empty }
        guard e.end > e.start else { throw PayloadError.invalidDates }
        var lines = ["BEGIN:VEVENT", "SUMMARY:\(escapeText(title))"]
        if !e.location.isEmpty { lines.append("LOCATION:\(escapeText(e.location))") }
        lines.append("DTSTART:\(utcStamp(e.start))")
        lines.append("DTEND:\(utcStamp(e.end))")
        if !e.notes.isEmpty { lines.append("DESCRIPTION:\(escapeText(e.notes))") }
        lines.append("END:VEVENT")
        return lines.joined(separator: "\r\n")
    }

    static func utcStamp(_ date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        return String(format: "%04d%02d%02dT%02d%02d%02dZ",
                      c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
    }

    /// Échappement texte commun à vCard et iCalendar.
    static func escapeText(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: "\r\n", with: "\\n")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
