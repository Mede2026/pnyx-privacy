import Foundation

/// Réponses de l'API Safe Browsing v5, lues en protobuf (le seul format accepté par l'API).
/// Numéros de champs : google/security/safebrowsing/v5/safebrowsing.proto.
enum SafeBrowsingAPI {
    /// Listes de 4 octets suivies. Les listes « Android » (uwsa, pha) ne concernent pas l'iPhone.
    static let listNames = ["se-4b", "mw-4b", "uws-4b"]

    /// RiceDeltaEncoded32Bit.
    struct RiceDelta {
        var firstValue: UInt32 = 0
        var riceParameter = 0
        var entriesCount = 0
        var encodedData = Data()

        init(protobuf data: Data) throws {
            for field in try ProtobufReader.fields(of: data) {
                switch field.number {
                case 1: firstValue = UInt32(truncatingIfNeeded: field.uint)
                case 2: riceParameter = Int(truncatingIfNeeded: field.uint)
                case 3: entriesCount = Int(truncatingIfNeeded: field.uint)
                case 4: encodedData = field.data
                default: break
                }
            }
        }

        func decoded() throws -> [UInt32] {
            try RiceDeltaDecoder.decode(firstValue: firstValue, riceParameter: riceParameter,
                                        entriesCount: entriesCount, encodedData: encodedData)
        }
    }

    /// HashList (hashList.get).
    struct HashList {
        var name = ""
        var version = Data()
        var partialUpdate = false
        var additionsFourBytes: RiceDelta?
        var compressedRemovals: RiceDelta?
        var minimumWaitDuration: TimeInterval?
        var sha256Checksum: Data?

        init(protobuf data: Data) throws {
            for field in try ProtobufReader.fields(of: data) {
                switch field.number {
                case 1: name = String(decoding: field.data, as: UTF8.self)
                case 2: version = field.data
                case 3: partialUpdate = field.uint != 0
                case 4: additionsFourBytes = try RiceDelta(protobuf: field.data)
                case 5: compressedRemovals = try RiceDelta(protobuf: field.data)
                case 6: minimumWaitDuration = try SafeBrowsingAPI.duration(field.data)
                case 7: sha256Checksum = field.data
                default: break
                }
            }
        }
    }

    struct FullHashDetail {
        var threatType: ThreatType?
        var attributes: Set<UInt64> = []

        /// CANARY (1) : test, à ne pas appliquer. FRAME_ONLY (2) : cadres seulement, pas une page ouverte.
        var isEnforceable: Bool { attributes.isDisjoint(with: [1, 2]) }

        init(protobuf data: Data) throws {
            for field in try ProtobufReader.fields(of: data) {
                switch field.number {
                case 1: threatType = SafeBrowsingAPI.threatType(field.uint)
                case 2: attributes.formUnion(try field.packedVarints())
                default: break
                }
            }
        }
    }

    struct FullHash {
        var fullHash = Data()
        var details: [FullHashDetail] = []

        init(protobuf data: Data) throws {
            for field in try ProtobufReader.fields(of: data) {
                switch field.number {
                case 1: fullHash = field.data
                case 2: details.append(try FullHashDetail(protobuf: field.data))
                default: break
                }
            }
        }
    }

    /// SearchHashesResponse (hashes.search).
    struct SearchResponse {
        var fullHashes: [FullHash] = []
        var cacheDuration: TimeInterval?

        init(protobuf data: Data) throws {
            for field in try ProtobufReader.fields(of: data) {
                switch field.number {
                case 1: fullHashes.append(try FullHash(protobuf: field.data))
                case 2: cacheDuration = try SafeBrowsingAPI.duration(field.data)
                default: break
                }
            }
        }
    }

    /// google.protobuf.Duration : secondes (1) et nanosecondes (2).
    static func duration(_ data: Data) throws -> TimeInterval {
        var seconds: UInt64 = 0
        var nanos: UInt64 = 0
        for field in try ProtobufReader.fields(of: data) {
            if field.number == 1 { seconds = field.uint }
            if field.number == 2 { nanos = field.uint }
        }
        return TimeInterval(seconds) + TimeInterval(nanos) / 1_000_000_000
    }

    /// Énumération ThreatType de l'API.
    static func threatType(_ value: UInt64) -> ThreatType? {
        switch value {
        case 1: .malware
        case 2: .socialEngineering
        case 3: .unwantedSoftware
        case 4: .potentiallyHarmfulApplication
        default: nil
        }
    }
}
