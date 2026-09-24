import CryptoKit
import Foundation
import Testing
@testable import QRCore

@Suite("Safe Browsing : canonisation et base locale")
struct SafeBrowsingTests {
    private func canonical(_ raw: String) -> String? {
        URLCanonicalizer.canonicalize(raw).map { "\($0.host)\($0.path)" + ($0.query.map { "?" + $0 } ?? "") }
    }

    /// Exemples tirés de la spécification Safe Browsing (« URLs and Hashing »).
    @Test(arguments: [
        ("http://host/%25%32%35", "host/%25"),
        ("http://host/%25%32%35%25%32%35", "host/%25%25"),
        ("http://www.google.com/blah/..", "www.google.com/"),
        ("www.google.com/", "www.google.com/"),
        ("www.google.com", "www.google.com/"),
        ("http://www.GOOgle.com/", "www.google.com/"),
        ("http://www.google.com.../", "www.google.com/"),
        ("http://www.google.com/foo\tbar\rbaz\n2", "www.google.com/foobarbaz2"),
        ("http://www.google.com/q?", "www.google.com/q?"),
        ("http://www.google.com/q?r?", "www.google.com/q?r?"),
        ("http://evil.com/foo#bar#baz", "evil.com/foo"),
        ("http://evil.com/foo;", "evil.com/foo;"),
        ("http://notrailingslash.com", "notrailingslash.com/"),
        ("http://www.gotaport.com:1234/", "www.gotaport.com/"),
        ("  http://www.google.com/  ", "www.google.com/"),
        ("http://host.com/ab%23cd", "host.com/ab%23cd"),
        ("http://host.com//twoslashes?more//slashes", "host.com/twoslashes?more//slashes")
    ])
    func canonicalization(raw: String, expected: String) {
        #expect(canonical(raw) == expected)
    }

    @Test func expressionsFollowTheSpecExample() throws {
        let canonical = try #require(URLCanonicalizer.canonicalize("http://a.b.c/1/2.html?param=1"))
        #expect(Set(URLCanonicalizer.expressions(for: canonical)) == [
            "a.b.c/1/2.html?param=1", "a.b.c/1/2.html", "a.b.c/", "a.b.c/1/",
            "b.c/1/2.html?param=1", "b.c/1/2.html", "b.c/", "b.c/1/"
        ])
    }

    @Test func prefixListAppliesUpdatesAndMatches() throws {
        let hash = Data(SHA256.hash(data: Data("evil.com/".utf8)))
        let evil = try #require(HashPrefixList.prefix(of: hash))
        let other: UInt32 = 0xABAB_ABAB
        var list = HashPrefixList()
        try list.apply(partialUpdate: false, removals: [], additions: [other, evil], newVersion: "v1",
                       checksum: HashPrefixList.checksum(of: [evil, other].sorted()))
        #expect(list.version == "v1")
        #expect(list.contains(prefixOf: hash))

        // Retrait par indice de la liste triée, avant les ajouts.
        let index: UInt32 = evil < other ? 0 : 1
        try list.apply(partialUpdate: true, removals: [index], additions: [], newVersion: "v2", checksum: nil)
        #expect(!list.contains(prefixOf: hash))
        #expect(list.version == "v2")
    }

    @Test func badChecksumIsRejected() {
        var list = HashPrefixList()
        #expect(throws: HashPrefixList.UpdateError.self) {
            try list.apply(partialUpdate: false, removals: [], additions: [0x0102_0304], newVersion: "x",
                           checksum: Data(repeating: 0, count: 32))
        }
        #expect(throws: HashPrefixList.UpdateError.self) {
            try list.apply(partialUpdate: true, removals: [3], additions: [], newVersion: "x", checksum: nil)
        }
    }

    /// Exemple de la documentation v5 (« Local Database », codage Golomb-Rice, k = 30).
    @Test func riceDecodingMatchesTheSpecExample() throws {
        let encoded = Data([0x74, 0x00, 0xD2, 0x97, 0x1B, 0xED, 0x49, 0x74, 0x00])
        let values = try RiceDeltaDecoder.decode(firstValue: 0x1D32_C508, riceParameter: 30, entriesCount: 2, encodedData: encoded)
        #expect(values == [0x1D32_C508, 0x291B_C542, 0xF7A5_02E5])
        #expect(try RiceDeltaDecoder.decode(firstValue: 7, riceParameter: 0, entriesCount: 0, encodedData: Data()) == [7])
        #expect(throws: RiceDeltaDecoder.DecodingError.self) {
            try RiceDeltaDecoder.decode(firstValue: 1, riceParameter: 30, entriesCount: 2, encodedData: Data([0x74]))
        }
    }

    /// Réponse protobuf de hashList.get (champs par défaut omis, comme le fait l'API) appliquée à une liste vide.
    @Test func hashListResponseDecodesAndApplies() throws {
        typealias PB = ProtobufWriter
        let values: [UInt32] = [0x1D32_C508, 0x291B_C542, 0xF7A5_02E5]
        let additions = PB.field(1, varint: 0x1D32_C508) + PB.field(2, varint: 30) + PB.field(3, varint: 2)
            + PB.field(4, bytes: Data([0x74, 0x00, 0xD2, 0x97, 0x1B, 0xED, 0x49, 0x74, 0x00]))
        let message = PB.field(1, string: "mw-4b") + PB.field(2, bytes: Data([1, 2]))
            + PB.field(4, bytes: additions) + PB.field(6, bytes: PB.field(1, varint: 1800))
            + PB.field(7, bytes: HashPrefixList.checksum(of: values))
            + PB.field(99, varint: 7) // champ inconnu : ignoré
        let response = try SafeBrowsingAPI.HashList(protobuf: message)
        #expect(response.name == "mw-4b")
        #expect(response.minimumWaitDuration == 1800)
        var list = HashPrefixList()
        try list.apply(partialUpdate: response.partialUpdate, removals: response.compressedRemovals?.decoded() ?? [],
                       additions: response.additionsFourBytes?.decoded() ?? [],
                       newVersion: response.version.base64EncodedString(), checksum: response.sha256Checksum)
        #expect(list.version == "AQI=")
        #expect(list.contains(prefixOf: SafeBrowsingClient.bytes(0x291B_C542) + Data(repeating: 0, count: 28)))

        // Stockage compact : relu à l'identique.
        let stored = try PropertyListDecoder().decode(HashPrefixList.self, from: PropertyListEncoder().encode(list))
        #expect(stored.version == list.version)
        #expect(stored.contains(prefixOf: SafeBrowsingClient.bytes(0xF7A5_02E5)))
    }

    /// Réponse de hashes.search : attributs empaquetés ou non, menaces inconnues ignorées.
    @Test func searchResponseDecodes() throws {
        typealias PB = ProtobufWriter
        let hash = Data(repeating: 1, count: 32)
        let phishing = PB.field(1, varint: 2)
        let canary = PB.field(1, varint: 1) + PB.field(2, bytes: PB.varint(1))
        let unknown = PB.field(1, varint: 42)
        let fullHash = PB.field(1, bytes: hash) + PB.field(2, bytes: phishing) + PB.field(2, bytes: canary)
            + PB.field(2, bytes: unknown)
        let message = PB.field(1, bytes: fullHash) + PB.field(2, bytes: PB.field(1, varint: 300) + PB.field(2, varint: 500_000_000))
        let response = try SafeBrowsingAPI.SearchResponse(protobuf: message)
        let entry = try #require(response.fullHashes.first)
        #expect(entry.fullHash == hash)
        #expect(entry.details.map(\.threatType) == [.socialEngineering, .malware, nil])
        #expect(entry.details.map(\.isEnforceable) == [true, false, true])
        #expect(response.cacheDuration == 300.5)
    }

    @Test func truncatedProtobufIsRejected() {
        #expect(throws: ProtobufReader.ReadError.self) {
            try SafeBrowsingAPI.HashList(protobuf: Data([0x0A, 0x05, 0x61]))
        }
    }

    @Test func noDatabaseMeansUnknown() async throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let client = SafeBrowsingClient(directory: directory)
        let url = try #require(URL(string: "https://exemple.com"))
        #expect(await client.check(url, apiKey: "clé") == .unknown)
    }
}
