import CryptoKit
import Foundation

/// Liste locale de préfixes de 4 octets (listes « -4b » de l'API v5), triés par valeur.
struct HashPrefixList: Codable, Sendable {
    /// Version opaque renvoyée par le serveur (base64), à renvoyer telle quelle.
    var version: String = ""
    /// Préfixes lus en gros-boutiste, triés : même ordre que les octets.
    private(set) var prefixes: [UInt32] = []

    enum UpdateError: Error {
        case badChecksum
        case badIndex
    }

    init() {}

    /// Applique une mise à jour complète ou partielle, puis vérifie la somme SHA-256 annoncée.
    /// Les retraits portent sur les indices de la liste triée, avant les ajouts.
    mutating func apply(partialUpdate: Bool, removals: [UInt32], additions: [UInt32], newVersion: String, checksum: Data?) throws {
        var working = partialUpdate ? prefixes : []
        if !removals.isEmpty {
            let removed = Set(removals)
            guard removed.allSatisfy({ Int($0) < working.count }) else { throw UpdateError.badIndex }
            working = working.enumerated().compactMap { removed.contains(UInt32($0.offset)) ? nil : $0.element }
        }
        working.append(contentsOf: additions)
        working.sort()
        if let checksum, !checksum.isEmpty {
            guard Self.checksum(of: working) == checksum else { throw UpdateError.badChecksum }
        }
        prefixes = working
        version = newVersion
    }

    /// Vrai si les 4 premiers octets du hachage complet sont dans la liste (recherche dichotomique).
    func contains(prefixOf fullHash: Data) -> Bool {
        guard let prefix = Self.prefix(of: fullHash) else { return false }
        var low = 0
        var high = prefixes.count - 1
        while low <= high {
            let middle = (low + high) / 2
            if prefixes[middle] == prefix { return true }
            if prefixes[middle] < prefix { low = middle + 1 } else { high = middle - 1 }
        }
        return false
    }

    var isEmpty: Bool { prefixes.isEmpty }

    static func prefix(of fullHash: Data) -> UInt32? {
        guard fullHash.count >= 4 else { return nil }
        return fullHash.prefix(4).reduce(0) { $0 << 8 | UInt32($1) }
    }

    /// SHA-256 de la liste triée, chaque préfixe écrit sur 4 octets gros-boutistes.
    static func checksum(of sorted: [UInt32]) -> Data {
        Data(SHA256.hash(data: packed(sorted)))
    }

    private static func packed(_ values: [UInt32]) -> Data {
        var data = Data(capacity: values.count * 4)
        for value in values { withUnsafeBytes(of: value.bigEndian) { data.append(contentsOf: $0) } }
        return data
    }

    // MARK: - Stockage compact (4 octets par préfixe)

    private enum CodingKeys: String, CodingKey { case version, packed }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decode(String.self, forKey: .version)
        let data = try container.decode(Data.self, forKey: .packed)
        let bytes = [UInt8](data)
        prefixes = stride(from: 0, to: bytes.count - 3, by: 4).map {
            UInt32(bytes[$0]) << 24 | UInt32(bytes[$0 + 1]) << 16 | UInt32(bytes[$0 + 2]) << 8 | UInt32(bytes[$0 + 3])
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(version, forKey: .version)
        try container.encode(Self.packed(prefixes), forKey: .packed)
    }
}
