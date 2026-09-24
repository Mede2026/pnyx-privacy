import Foundation

/// Écriture protobuf minimale, pour fabriquer des réponses de l'API dans les tests.
enum ProtobufWriter {
    static func varint(_ value: UInt64) -> Data {
        var value = value
        var data = Data()
        while value >= 0x80 {
            data.append(UInt8(value & 0x7F) | 0x80)
            value >>= 7
        }
        data.append(UInt8(value))
        return data
    }

    static func field(_ number: Int, varint value: UInt64) -> Data {
        varint(UInt64(number << 3)) + varint(value)
    }

    static func field(_ number: Int, bytes: Data) -> Data {
        varint(UInt64(number << 3 | 2)) + varint(UInt64(bytes.count)) + bytes
    }

    static func field(_ number: Int, string: String) -> Data {
        field(number, bytes: Data(string.utf8))
    }
}
