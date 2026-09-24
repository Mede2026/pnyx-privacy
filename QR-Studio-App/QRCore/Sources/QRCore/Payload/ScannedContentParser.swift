import Foundation

/// Détermine le type d'une chaîne décodée. Les préfixes sont testés du plus spécifique
/// au plus général ; le premier qui correspond gagne.
public enum ScannedContentParser {
    public static func parse(_ raw: String, symbology: Symbology? = nil) -> ParsedContent {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let upper = text.uppercased()

        if upper.hasPrefix("WIFI:"), let wifi = StructuredParsers.wifi(text) {
            return .wifi(wifi)
        }
        if upper.hasPrefix("BEGIN:VCARD") {
            return .contact(StructuredParsers.vCard(text))
        }
        if upper.hasPrefix("MECARD:") {
            return .contact(StructuredParsers.meCard(text))
        }
        if let point = location(text) {
            return .location(point)
        }
        if upper.hasPrefix("MAILTO:"), let email = mailto(text) {
            return .email(email)
        }
        if upper.hasPrefix("MATMSG:") {
            return .email(StructuredParsers.matmsg(text))
        }
        if upper.hasPrefix("SMSTO:") || upper.hasPrefix("SMS:") {
            return .sms(sms(text))
        }
        if upper.hasPrefix("TEL:") {
            return .phone(String(text.dropFirst(4)).removingPercentEncoding ?? String(text.dropFirst(4)))
        }
        if upper.hasPrefix("BEGIN:VEVENT") || (upper.hasPrefix("BEGIN:VCALENDAR") && upper.contains("BEGIN:VEVENT")) {
            return .event(StructuredParsers.vEvent(text))
        }
        if upper.hasPrefix("HTTP://") || upper.hasPrefix("HTTPS://"), let url = URL(string: text) ?? encodedURL(text) {
            if let product = digitalLink(url) {
                return .product(product)
            }
            return .url(url)
        }
        if let crypto = crypto(text) {
            return .crypto(crypto)
        }
        if let product = productCode(text, symbology: symbology) {
            return .product(product)
        }
        return .text(raw)
    }

    // MARK: - Localisation

    /// geo:lat,lon ou liens Plans / Google Maps contenant des coordonnées.
    static func location(_ text: String) -> GeoPoint? {
        let lower = text.lowercased()
        if lower.hasPrefix("geo:") {
            let body = text.dropFirst(4)
            let coordinatePart = body.split(whereSeparator: { $0 == "?" || $0 == ";" }).first ?? ""
            var query: String?
            if let range = body.range(of: "q=") {
                query = String(body[range.upperBound...]).removingPercentEncoding
            }
            guard let point = coordinates(String(coordinatePart)) else { return nil }
            return GeoPoint(latitude: point.0, longitude: point.1, query: query)
        }
        guard lower.hasPrefix("http"), let components = URLComponents(string: text),
              let host = components.host?.lowercased() else { return nil }
        let isAppleMaps = host == "maps.apple.com" || host == "maps.apple"
        let isGoogleMaps = host.hasPrefix("maps.google.") || ((host.hasSuffix("google.com") || host.hasPrefix("www.google.")) && components.path.hasPrefix("/maps"))
        guard isAppleMaps || isGoogleMaps else { return nil }
        let items = components.queryItems ?? []
        for key in ["ll", "q", "sll", "coordinate", "query", "destination", "daddr"] {
            if let value = items.first(where: { $0.name == key })?.value, let point = coordinates(value) {
                return GeoPoint(latitude: point.0, longitude: point.1, query: nil)
            }
        }
        // Google Maps : …/@45.5906,-73.4503,15z
        if let at = components.path.range(of: "@"),
           let point = coordinates(String(components.path[at.upperBound...])) {
            return GeoPoint(latitude: point.0, longitude: point.1, query: nil)
        }
        return nil
    }

    static func coordinates(_ text: String) -> (Double, Double)? {
        let parts = text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count >= 2, let latitude = Double(parts[0]), let longitude = Double(parts[1]),
              (-90...90).contains(latitude), (-180...180).contains(longitude) else { return nil }
        return (latitude, longitude)
    }

    // MARK: - Courriel et SMS

    static func mailto(_ text: String) -> EmailMessage? {
        let body = String(text.dropFirst("mailto:".count))
        let parts = body.split(separator: "?", maxSplits: 1)
        let to = parts.first.map { String($0).removingPercentEncoding ?? String($0) } ?? ""
        var subject = ""
        var message = ""
        if parts.count == 2 {
            for pair in parts[1].split(separator: "&") {
                let kv = pair.split(separator: "=", maxSplits: 1)
                guard kv.count == 2 else { continue }
                let value = String(kv[1]).replacingOccurrences(of: "+", with: "%2B").removingPercentEncoding ?? ""
                switch kv[0].lowercased() {
                case "subject": subject = value
                case "body": message = value
                default: break
                }
            }
        }
        return EmailMessage(to: to, subject: subject, body: message)
    }

    /// SMSTO:numéro:message ou sms:numéro?body=message
    static func sms(_ text: String) -> SMSMessage {
        if text.uppercased().hasPrefix("SMSTO:") {
            let parts = text.dropFirst(6).split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            return SMSMessage(number: parts.first.map(String.init) ?? "",
                              body: parts.count > 1 ? String(parts[1]) : "")
        }
        let rest = String(text.dropFirst(4))
        let parts = rest.split(whereSeparator: { $0 == "?" || $0 == "&" })
        let number = parts.first.map(String.init) ?? ""
        var body = ""
        for part in parts.dropFirst() where part.lowercased().hasPrefix("body=") {
            body = String(part.dropFirst(5)).removingPercentEncoding ?? String(part.dropFirst(5))
        }
        return SMSMessage(number: number, body: body)
    }

    // MARK: - Produits

    /// GS1 Digital Link : /01/ suivi du GTIN, quel que soit le domaine.
    /// La norme exige 14 chiffres ; les formes courtes (8, 12, 13) sont aussi acceptées et normalisées.
    public static func digitalLink(_ url: URL) -> ProductInfo? {
        let segments = url.path.split(separator: "/").map(String.init)
        guard let index = segments.firstIndex(of: "01"), index + 1 < segments.count else { return nil }
        let candidate = segments[index + 1]
        guard [8, 12, 13, 14].contains(candidate.count), GTIN.digits(of: candidate) != nil,
              let gtin = GTIN.normalized(candidate) else { return nil }
        return ProductInfo(code: candidate, gtin: gtin, manufacturerURL: url)
    }

    static func productCode(_ text: String, symbology: Symbology?) -> ProductInfo? {
        guard GTIN.digits(of: text) != nil else { return nil }
        var code = text
        if symbology == .upcE, let expanded = GTIN.expandUPCE(text) { code = expanded }
        let isProductSymbology = symbology?.isProductCode ?? false
        guard (12...14).contains(code.count) || (isProductSymbology && code.count == 8),
              let gtin = GTIN.normalized(code) else { return nil }
        return ProductInfo(code: code, gtin: gtin, manufacturerURL: nil)
    }

    // MARK: - Cryptomonnaie

    static func crypto(_ text: String) -> CryptoPayment? {
        guard let colon = text.firstIndex(of: ":") else { return nil }
        let scheme = text[..<colon].lowercased()
        guard CryptoNetwork(rawValue: scheme) != nil else { return nil }
        let rest = text[text.index(after: colon)...]
        let parts = rest.split(separator: "?", maxSplits: 1)
        guard let address = parts.first, !address.isEmpty else { return nil }
        var amount: String?
        if parts.count == 2 {
            for pair in parts[1].split(separator: "&") {
                let kv = pair.split(separator: "=", maxSplits: 1)
                if kv.count == 2, ["amount", "value"].contains(kv[0].lowercased()) { amount = String(kv[1]) }
            }
        }
        return CryptoPayment(network: scheme, address: String(address), amount: amount)
    }

    private static func encodedURL(_ text: String) -> URL? {
        text.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed).flatMap(URL.init(string:))
    }
}
