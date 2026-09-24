import CryptoKit
import Foundation

public enum ErrorCorrection: String, CaseIterable, Codable, Sendable, Identifiable {
    case L, M, Q, H

    public var id: String { rawValue }

    /// Part des données récupérable.
    public var recoveryPercent: Int {
        switch self {
        case .L: 7
        case .M: 15
        case .Q: 25
        case .H: 30
        }
    }

    /// Capacité maximale en octets (mode octet, version 40).
    public var qrByteCapacity: Int {
        switch self {
        case .L: 2953
        case .M: 2331
        case .Q: 1663
        case .H: 1273
        }
    }
}
