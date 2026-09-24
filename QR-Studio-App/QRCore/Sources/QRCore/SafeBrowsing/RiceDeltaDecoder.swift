import Foundation

/// Décodage Golomb-Rice des listes Safe Browsing v5 (valeurs de 32 bits).
/// Chaque écart entre deux valeurs triées s'écrit : quotient en unaire (des 1 terminés par un 0),
/// puis reste sur `riceParameter` bits. Les bits se lisent du poids faible au poids fort, octet par octet.
enum RiceDeltaDecoder {
    enum DecodingError: Error {
        case truncated
        case badParameter
    }

    /// Renvoie `entriesCount + 1` valeurs : la première, puis chaque valeur précédente plus son écart.
    static func decode(firstValue: UInt32, riceParameter: Int, entriesCount: Int, encodedData: Data) throws -> [UInt32] {
        guard entriesCount > 0 else { return [firstValue] }
        guard (1...31).contains(riceParameter) else { throw DecodingError.badParameter }
        var reader = BitReader(bytes: [UInt8](encodedData))
        var values = [firstValue]
        values.reserveCapacity(entriesCount + 1)
        var current = firstValue
        for _ in 0..<entriesCount {
            var quotient: UInt32 = 0
            while try reader.next() == 1 { quotient &+= 1 }
            let remainder = try reader.next(bits: riceParameter)
            current &+= (quotient &<< UInt32(riceParameter)) | remainder
            values.append(current)
        }
        return values
    }

    private struct BitReader {
        let bytes: [UInt8]
        var position = 0

        mutating func next() throws -> UInt32 {
            guard position < bytes.count * 8 else { throw DecodingError.truncated }
            let bit = (bytes[position / 8] >> UInt8(position % 8)) & 1
            position += 1
            return UInt32(bit)
        }

        mutating func next(bits count: Int) throws -> UInt32 {
            var value: UInt32 = 0
            for index in 0..<count { value |= try next() << UInt32(index) }
            return value
        }
    }
}
