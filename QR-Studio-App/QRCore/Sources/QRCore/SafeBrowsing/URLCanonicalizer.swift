import CryptoKit
import Foundation

/// Canonisation des URL et expressions « suffixe d'hôte / préfixe de chemin »
/// selon la spécification Safe Browsing (section « URLs and Hashing », identique en v4 et v5).
public enum URLCanonicalizer {
    public struct Canonical: Equatable, Sendable {
        public var host: String
        public var path: String
        public var query: String?
    }

    public static func canonicalize(_ raw: String) -> Canonical? {
        // 1. Retire tabulations et retours à la ligne, espaces de bord et fragment.
        var text = raw.replacingOccurrences(of: "\t", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespaces)
        if let hash = text.firstIndex(of: "#") { text = String(text[..<hash]) }
        // 2. Décodage répété jusqu'à ce qu'il n'y ait plus d'échappement.
        text = repeatedlyUnescape(text)
        if !text.contains("://") { text = "http://" + text }

        guard let schemeEnd = text.range(of: "://") else { return nil }
        let rest = text[schemeEnd.upperBound...]
        let hostEnd = rest.firstIndex(where: { $0 == "/" || $0 == "?" }) ?? rest.endIndex
        var host = String(rest[..<hostEnd])
        var pathAndQuery = String(rest[hostEnd...])

        // Hôte : sans identifiants ni port, minuscules, points de bord retirés, points consécutifs fusionnés.
        if let at = host.lastIndex(of: "@") { host = String(host[host.index(after: at)...]) }
        if let colon = host.lastIndex(of: ":"), !host.hasPrefix("[") { host = String(host[..<colon]) }
        host = host.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
        while host.contains("..") { host = host.replacingOccurrences(of: "..", with: ".") }
        guard !host.isEmpty else { return nil }

        var query: String?
        if let questionMark = pathAndQuery.firstIndex(of: "?") {
            query = String(pathAndQuery[pathAndQuery.index(after: questionMark)...])
            pathAndQuery = String(pathAndQuery[..<questionMark])
        }
        let path = normalizePath(pathAndQuery.isEmpty ? "/" : pathAndQuery)

        return Canonical(host: escape(host), path: escape(path), query: query.map(escape))
    }

    /// Combinaisons à tester : jusqu'à 5 hôtes × 6 chemins.
    public static func expressions(for canonical: Canonical) -> [String] {
        var hosts = [canonical.host]
        if !isIPAddress(canonical.host) {
            let components = canonical.host.split(separator: ".").map(String.init)
            let lastFive = Array(components.suffix(5))
            if lastFive.count >= 2 {
                for start in 0..<(lastFive.count - 1) {
                    let candidate = lastFive[start...].joined(separator: ".")
                    if candidate != canonical.host, !hosts.contains(candidate) { hosts.append(candidate) }
                    if hosts.count == 5 { break }
                }
            }
        }

        var paths: [String] = []
        if let query = canonical.query { paths.append(canonical.path + "?" + query) }
        paths.append(canonical.path)
        let segments = canonical.path.split(separator: "/", omittingEmptySubsequences: true).map(String.init)
        // Seuls les dossiers forment des préfixes : le dernier segment d'un chemin sans « / » final est un fichier.
        let directories = canonical.path.hasSuffix("/") ? segments : Array(segments.dropLast())
        var prefix = "/"
        if !paths.contains(prefix) { paths.append(prefix) }
        for segment in directories.prefix(3) {
            prefix += segment + "/"
            if !paths.contains(prefix), paths.count < 6 { paths.append(prefix) }
        }

        return hosts.flatMap { host in paths.map { host + $0 } }
    }

    /// SHA-256 complet de chaque expression.
    public static func hashes(for raw: String) -> [Data] {
        guard let canonical = canonicalize(raw) else { return [] }
        return expressions(for: canonical).map { Data(SHA256.hash(data: Data($0.utf8))) }
    }

    private static func repeatedlyUnescape(_ text: String) -> String {
        var current = text
        for _ in 0..<10 {
            guard let decoded = current.removingPercentEncoding, decoded != current else { break }
            current = decoded
        }
        return current
    }

    /// Résout /./ et /../, et fusionne les barres obliques consécutives.
    private static func normalizePath(_ path: String) -> String {
        let trailingSlash = path.hasSuffix("/")
        var output: [Substring] = []
        for segment in path.split(separator: "/", omittingEmptySubsequences: true) {
            if segment == "." { continue }
            if segment == ".." {
                if !output.isEmpty { output.removeLast() }
                continue
            }
            output.append(segment)
        }
        var result = "/" + output.joined(separator: "/")
        if trailingSlash, result != "/" { result += "/" }
        return result
    }

    /// Échappe les octets ≤ 32, ≥ 127, « # » et « % ».
    private static func escape(_ text: String) -> String {
        var result = ""
        for byte in text.utf8 {
            if byte <= 32 || byte >= 127 || byte == UInt8(ascii: "#") || byte == UInt8(ascii: "%") {
                result += String(format: "%%%02X", byte)
            } else {
                result.append(Character(Unicode.Scalar(byte)))
            }
        }
        return result
    }

    private static func isIPAddress(_ host: String) -> Bool {
        let parts = host.split(separator: ".")
        return parts.count == 4 && parts.allSatisfy { UInt8($0) != nil }
    }
}
