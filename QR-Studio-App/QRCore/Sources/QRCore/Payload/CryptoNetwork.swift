import Foundation

public enum CryptoNetwork: String, CaseIterable, Codable, Sendable, Identifiable {
    case bitcoin, ethereum, litecoin, bitcoincash, dogecoin

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .bitcoin: "Bitcoin"
        case .ethereum: "Ethereum"
        case .litecoin: "Litecoin"
        case .bitcoincash: "Bitcoin Cash"
        case .dogecoin: "Dogecoin"
        }
    }
}
