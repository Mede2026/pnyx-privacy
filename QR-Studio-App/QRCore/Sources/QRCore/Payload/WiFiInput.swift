import Foundation

public struct WiFiInput: Codable, Sendable, Hashable {
    public var ssid = ""
    public var password = ""
    public var security: WiFiSecurity = .wpa
    public var hidden = false
    public init() {}
}
