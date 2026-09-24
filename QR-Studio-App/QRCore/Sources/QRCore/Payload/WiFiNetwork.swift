import Foundation

public struct WiFiNetwork: Sendable, Hashable {
    public init(ssid: String, password: String, security: String, hidden: Bool, identity: String? = nil, eapMethod: String? = nil) {
        self.ssid = ssid
        self.password = password
        self.security = security
        self.hidden = hidden
        self.identity = identity
        self.eapMethod = eapMethod
    }

    public var ssid: String
    public var password: String
    /// Valeur brute du champ T : WPA, WEP, nopass, WPA2-EAP…
    public var security: String
    public var hidden: Bool
    public var identity: String?
    public var eapMethod: String?

    public var isEnterprise: Bool { security.uppercased().contains("EAP") || eapMethod != nil }
    public var isOpen: Bool { security.lowercased() == "nopass" || (security.isEmpty && password.isEmpty) }
}
