import Foundation

public struct CryptoPayment: Sendable, Hashable {
    public init(network: String, address: String, amount: String? = nil) {
        self.network = network
        self.address = address
        self.amount = amount
    }

    public var network: String
    public var address: String
    public var amount: String?
}
