import Foundation

/// Champs de formulaire de chaque type de contenu. L'utilisateur ne tape jamais la syntaxe.
public enum WiFiSecurity: String, CaseIterable, Codable, Sendable, Identifiable {
    case wpa = "WPA"
    case wep = "WEP"
    case none = "nopass"
    public var id: String { rawValue }
}
