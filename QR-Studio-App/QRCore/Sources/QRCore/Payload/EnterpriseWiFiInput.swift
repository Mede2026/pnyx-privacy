import Foundation

public struct EnterpriseWiFiInput: Codable, Sendable, Hashable {
    public var ssid = ""
    public var identity = ""
    public var password = ""
    public var eap: EAPMethod = .peap
    public init() {}
}
