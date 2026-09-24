import Foundation
import Security

/// Message envoyé par l'iPhone : une ligne JSON par scan.
public struct MacLinkMessage: Codable, Sendable, Equatable {
    public var payload: String
    public var symbology: String
    public var date: Date

    public init(payload: String, symbology: String, date: Date = .now) {
        self.payload = payload
        self.symbology = symbology
        self.date = date
    }

    public func encodedLine() throws -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self) + Data([0x0A])
    }

    public static func decode(line: Data) throws -> MacLinkMessage {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(MacLinkMessage.self, from: line)
    }
}
