import Foundation

/// Lecteur protobuf minimal : l'API Safe Browsing v5 ne répond qu'en protobuf.
/// Il ne lit que ce dont l'app a besoin (entiers, octets, sous-messages) et ignore le reste.
struct ProtobufReader {
    enum ReadError: Error {
        case truncated
        case unsupportedWireType(Int)
    }

    enum Value {
        case varint(UInt64)
        case bytes(Data)
        case fixed
    }

    struct Field {
        let number: Int
        let value: Value

        var uint: UInt64 { if case .varint(let value) = value { value } else { 0 } }
        var data: Data { if case .bytes(let data) = value { data } else { Data() } }

        /// Entiers répétés, empaquetés (un bloc d'octets) ou non (un champ par valeur).
        func packedVarints() throws -> [UInt64] {
            switch value {
            case .varint(let value):
                return [value]
            case .bytes(let data):
                var reader = ProtobufReader(data)
                var values: [UInt64] = []
                while !reader.isAtEnd { values.append(try reader.varint()) }
                return values
            case .fixed:
                return []
            }
        }
    }

    private let bytes: [UInt8]
    private var position = 0

    init(_ data: Data) {
        bytes = [UInt8](data)
    }

    var isAtEnd: Bool { position >= bytes.count }

    /// Tous les champs du message, dans l'ordre.
    static func fields(of data: Data) throws -> [Field] {
        var reader = ProtobufReader(data)
        var fields: [Field] = []
        while !reader.isAtEnd { fields.append(try reader.field()) }
        return fields
    }

    mutating func field() throws -> Field {
        let tag = try varint()
        let number = Int(tag >> 3)
        switch Int(tag & 7) {
        case 0:
            return Field(number: number, value: .varint(try varint()))
        case 1:
            try skip(8)
            return Field(number: number, value: .fixed)
        case 2:
            let length = Int(try varint())
            guard length >= 0, position + length <= bytes.count else { throw ReadError.truncated }
            let data = Data(bytes[position ..< position + length])
            position += length
            return Field(number: number, value: .bytes(data))
        case 5:
            try skip(4)
            return Field(number: number, value: .fixed)
        case let wireType:
            throw ReadError.unsupportedWireType(wireType)
        }
    }

    mutating func varint() throws -> UInt64 {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        while true {
            guard position < bytes.count, shift < 64 else { throw ReadError.truncated }
            let byte = bytes[position]
            position += 1
            result |= UInt64(byte & 0x7F) << shift
            if byte < 0x80 { return result }
            shift += 7
        }
    }

    private mutating func skip(_ count: Int) throws {
        guard position + count <= bytes.count else { throw ReadError.truncated }
        position += count
    }
}
