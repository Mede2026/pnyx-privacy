import Foundation

public enum URLSafety {
    static let shorteners: Set<String> = [
        "bit.ly", "tinyurl.com", "t.co", "goo.gl", "ow.ly", "is.gd", "buff.ly", "rebrand.ly", "cutt.ly",
        "shorturl.at", "tiny.cc", "s.id", "rb.gy", "t.ly", "lnkd.in", "qrco.de", "bl.ink", "short.io",
        "tinyurl.ca", "v.gd", "shorte.st", "adf.ly", "bitly.com", "qr.net", "go.aws", "trib.al"
    ]

    static let paymentHosts: Set<String> = [
        "paypal.me", "paypal.com", "venmo.com", "cash.app", "buy.stripe.com", "checkout.stripe.com",
        "pay.google.com", "wise.com", "revolut.me", "monzo.me", "square.link", "checkout.square.site",
        "paylink.interac.ca", "etransfer.interac.ca", "pay.apple.com", "link.me"
    ]

    public static func analyze(_ url: URL) -> URLSafetyReport {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let host = (components?.host ?? url.host() ?? "").lowercased()
        var warnings: [URLSafetyReport.Warning] = []

        if url.scheme?.lowercased() == "http" { warnings.append(.notEncrypted) }

        let decoded = decodedHost(host)
        if host.contains("xn--") || host.unicodeScalars.contains(where: { !$0.isASCII }) {
            warnings.append(.deceptiveCharacters(decodedHost: decoded))
        }
        let bareHost = host.hasPrefix("www.") ? String(host.dropFirst(4)) : host
        if shorteners.contains(bareHost) { warnings.append(.shortener) }
        if isIPAddress(host) { warnings.append(.ipAddress) }
        if components?.user != nil || components?.password != nil { warnings.append(.embeddedCredentials) }
        if paymentHosts.contains(bareHost) || paymentHosts.contains(where: { bareHost.hasSuffix("." + $0) }) {
            warnings.append(.payment)
        }

        return URLSafetyReport(
            host: host,
            displayHost: decoded,
            path: components?.percentEncodedPath.removingPercentEncoding ?? url.path(),
            queryItems: components?.queryItems ?? [],
            warnings: warnings
        )
    }

    /// Schémas traités par l'app : tout autre schéma en tête d'un texte est signalé.
    static let knownSchemes: Set<String> = [
        "http", "https", "mailto", "tel", "sms", "smsto", "geo", "wifi", "mecard", "matmsg", "begin",
        "bitcoin", "ethereum", "litecoin", "bitcoincash", "dogecoin", "monero", "solana"
    ]

    /// Schémas qui peuvent exécuter du code ou lire des fichiers : jamais à ouvrir.
    static let dangerousSchemes: Set<String> = ["javascript", "vbscript", "data", "file", "intent", "content"]

    /// Schéma inhabituel en tête d'un texte (« javascript: », « itms-services: »…), ou nil.
    public static func unusualScheme(in text: String) -> (scheme: String, isDangerous: Bool)? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let colon = trimmed.firstIndex(of: ":") else { return nil }
        let scheme = trimmed[..<colon].lowercased()
        guard let first = scheme.first, first.isLetter, scheme.count <= 32,
              scheme.allSatisfy({ $0.isLetter || $0.isNumber || "+-.".contains($0) }),
              !knownSchemes.contains(scheme) else { return nil }
        // « Note: … » ou « Prix: 3 $ » ne sont pas des liens : il faut un texte sans espace.
        guard !trimmed.contains(" ") || dangerousSchemes.contains(scheme) else { return nil }
        return (scheme, dangerousSchemes.contains(scheme))
    }

    static func isIPAddress(_ host: String) -> Bool {
        let parts = host.split(separator: ".")
        if parts.count == 4, parts.allSatisfy({ UInt8($0) != nil }) { return true }
        return host.hasPrefix("[") || (host.contains(":") && host.allSatisfy { $0.isHexDigit || $0 == ":" })
    }

    /// Décode le punycode de chaque étiquette du domaine (RFC 3492), pour montrer les vrais caractères.
    public static func decodedHost(_ host: String) -> String {
        host.split(separator: ".").map { label -> String in
            guard label.hasPrefix("xn--"), let decoded = Punycode.decode(String(label.dropFirst(4))) else {
                return String(label)
            }
            return decoded
        }.joined(separator: ".")
    }
}
