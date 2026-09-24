import Foundation
import OSLog

/// Google Safe Browsing v5, mode « liste locale » : les listes de préfixes de hachage sont téléchargées
/// et la vérification se fait sur l'appareil. L'URL n'est jamais envoyée ; seul un préfixe de 4 octets
/// part vers Google (hashes.search), et seulement en cas de correspondance locale.
public actor SafeBrowsingClient {
    public static let shared = SafeBrowsingClient()

    private static let endpoint = "https://safebrowsing.googleapis.com/v5/"

    private struct CachedSearch {
        let expires: Date
        let threats: [Data: ThreatType]
    }

    private struct Stored: Codable {
        var lists: [String: HashPrefixList]
        var nextUpdate: Date
    }

    private var lists: [String: HashPrefixList] = [:]
    private var nextUpdate: Date = .distantPast
    private var loaded = false
    /// Résultats de hashes.search, gardés le temps indiqué par cacheDuration (mémoire seulement).
    private var searchCache: [UInt32: CachedSearch] = [:]
    private let storeURL: URL
    private let legacyStoreURL: URL
    /// Identifiant envoyé à Google : la clé est restreinte aux apps QR Studio.
    private let bundleIdentifier: String?

    public init(directory: URL? = nil, bundleIdentifier: String? = Bundle.main.bundleIdentifier) {
        self.bundleIdentifier = bundleIdentifier
        let base = directory ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        storeURL = base.appendingPathComponent("SafeBrowsing-v5.plist")
        legacyStoreURL = base.appendingPathComponent("SafeBrowsing.json")
    }

    /// Clé lue dans l'Info.plist (clé SafeBrowsingAPIKey, fournie par un fichier de configuration hors Git).
    public static var apiKey: String? {
        let key = Bundle.main.object(forInfoDictionaryKey: "SafeBrowsingAPIKey") as? String
        guard let key, !key.isEmpty, !key.hasPrefix("$(") else { return nil }
        return key
    }

    public var hasDatabase: Bool {
        loadIfNeeded()
        return lists.values.contains { !$0.isEmpty }
    }

    /// Délai minimal demandé par l'API avant la prochaine mise à jour.
    public var earliestNextUpdate: Date { nextUpdate }

    /// Met à jour chaque liste (hashList.get) si le délai demandé par l'API est écoulé.
    public func updateIfNeeded(apiKey: String) async throws {
        loadIfNeeded()
        guard Date.now >= nextUpdate else { return }
        var wait: TimeInterval = 0
        for name in SafeBrowsingAPI.listNames {
            var list = lists[name] ?? HashPrefixList()
            let query = list.version.isEmpty ? [] : [URLQueryItem(name: "version", value: list.version)]
            do {
                let response = try SafeBrowsingAPI.HashList(protobuf: try await get("hashList/\(name)", query: query, key: apiKey))
                try list.apply(partialUpdate: response.partialUpdate,
                               removals: try response.compressedRemovals?.decoded() ?? [],
                               additions: try response.additionsFourBytes?.decoded() ?? [],
                               newVersion: response.version.base64EncodedString(),
                               checksum: response.sha256Checksum)
                wait = max(wait, response.minimumWaitDuration ?? 1800)
            } catch let error as URLError {
                throw error
            } catch {
                // Somme de contrôle fausse ou données illisibles : mise à jour complète la prochaine fois.
                Logger.general.error("Liste Safe Browsing \(name) incohérente, réinitialisée : \(String(describing: error))")
                list = HashPrefixList()
            }
            lists[name] = list
        }
        nextUpdate = Date.now.addingTimeInterval(wait)
        try save()
    }

    /// Vérifie une URL : correspondance de préfixe locale, puis confirmation par hachage complet.
    public func check(_ url: URL, apiKey: String?) async -> SafeBrowsingVerdict {
        loadIfNeeded()
        guard let apiKey, hasDatabase else { return .unknown }
        let fullHashes = URLCanonicalizer.hashes(for: url.absoluteString)
        let matched = Set(fullHashes.filter { hash in lists.values.contains { $0.contains(prefixOf: hash) } }
            .compactMap(HashPrefixList.prefix(of:)))
        guard !matched.isEmpty else { return .safe }

        var threats: [Data: ThreatType] = [:]
        var pending: [UInt32] = []
        for prefix in matched.sorted() {
            if let cached = searchCache[prefix], cached.expires > .now {
                threats.merge(cached.threats) { current, _ in current }
            } else {
                pending.append(prefix)
            }
        }
        if !pending.isEmpty {
            do {
                threats.merge(try await search(pending, key: apiKey)) { current, _ in current }
            } catch {
                Logger.general.error("Confirmation Safe Browsing impossible : \(error.localizedDescription)")
                return .unknown
            }
        }
        for hash in fullHashes {
            if let threat = threats[hash] { return .unsafe(threat) }
        }
        return .safe
    }

    /// Efface la base locale (option coupée).
    public func reset() throws {
        lists = [:]
        searchCache = [:]
        nextUpdate = .distantPast
        for url in [storeURL, legacyStoreURL] where FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Réseau

    /// hashes.search : n'envoie que les préfixes de 4 octets, puis met les réponses en cache.
    private func search(_ prefixes: [UInt32], key: String) async throws -> [Data: ThreatType] {
        let query = prefixes.map { URLQueryItem(name: "hashPrefixes", value: Self.bytes($0).base64EncodedString()) }
        let response = try SafeBrowsingAPI.SearchResponse(protobuf: try await get("hashes:search", query: query, key: key))
        var found: [UInt32: [Data: ThreatType]] = [:]
        for entry in response.fullHashes {
            guard let prefix = HashPrefixList.prefix(of: entry.fullHash),
                  let threat = entry.details.filter(\.isEnforceable).compactMap(\.threatType)
                      .min(by: { $0.severityRank < $1.severityRank }) else { continue }
            found[prefix, default: [:]][entry.fullHash] = threat
        }
        let expires = Date.now.addingTimeInterval(response.cacheDuration ?? 300)
        var threats: [Data: ThreatType] = [:]
        for prefix in prefixes {
            let entries = found[prefix] ?? [:]
            searchCache[prefix] = CachedSearch(expires: expires, threats: entries)
            threats.merge(entries) { current, _ in current }
        }
        return threats
    }

    /// Requête GET ; la réponse est un message protobuf.
    private func get(_ method: String, query: [URLQueryItem], key: String) async throws -> Data {
        guard var components = URLComponents(string: Self.endpoint + method) else { throw URLError(.badURL) }
        // Encodage strict : « + », « / » et « = » du base64 ne doivent pas être pris pour des séparateurs.
        components.percentEncodedQueryItems = query.isEmpty ? nil : query.map {
            URLQueryItem(name: $0.name, value: $0.value?.addingPercentEncoding(withAllowedCharacters: .alphanumerics))
        }
        guard let url = components.url else { throw URLError(.badURL) }
        var request = URLRequest(url: url, timeoutInterval: 20)
        // La clé passe par un en-tête, jamais dans l'URL.
        request.setValue(key, forHTTPHeaderField: "X-Goog-Api-Key")
        request.setValue("application/x-protobuf", forHTTPHeaderField: "Accept")
        if let bundleID = bundleIdentifier {
            request.setValue(bundleID, forHTTPHeaderField: "X-Ios-Bundle-Identifier")
        }
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    // MARK: - Stockage

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        if FileManager.default.fileExists(atPath: legacyStoreURL.path) {
            do {
                try FileManager.default.removeItem(at: legacyStoreURL)
            } catch {
                Logger.general.error("Ancienne base Safe Browsing v4 non effacée : \(error.localizedDescription)")
            }
        }
        guard let data = FileManager.default.contents(atPath: storeURL.path) else { return }
        do {
            let stored = try PropertyListDecoder().decode(Stored.self, from: data)
            lists = stored.lists
            nextUpdate = stored.nextUpdate
        } catch {
            Logger.general.error("Base Safe Browsing illisible : \(error.localizedDescription)")
        }
    }

    private func save() throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        try FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoder.encode(Stored(lists: lists, nextUpdate: nextUpdate)).write(to: storeURL, options: .atomic)
    }

    static func bytes(_ prefix: UInt32) -> Data {
        withUnsafeBytes(of: prefix.bigEndian) { Data($0) }
    }
}
