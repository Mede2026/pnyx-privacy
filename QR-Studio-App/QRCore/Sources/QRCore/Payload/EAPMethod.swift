import Foundation

public enum EAPMethod: String, CaseIterable, Codable, Sendable, Identifiable {
    case peap = "PEAP"
    case ttls = "TTLS"
    case tls = "TLS"
    case pwd = "PWD"
    public var id: String { rawValue }
}
