import Foundation
import Security

/// Appairage iPhone ↔ Mac : le Mac affiche ce contenu en QR, l'iPhone le scanne.
/// Aucun compte, aucun serveur : la clé partagée sert à chiffrer la connexion (TLS à clé pré-partagée).
public struct MacLinkPairing: Codable, Sendable, Hashable, Identifiable {
    public static let scheme = "qrstudio-pair"

    public var id: UUID
    public var name: String
    /// Clé partagée de 32 octets.
    public var key: Data

    public init(id: UUID, name: String, key: Data) {
        self.id = id
        self.name = name
        self.key = key
    }

    /// Nouvelle identité avec une clé aléatoire (générateur cryptographique du système).
    public static func generate(name: String) throws -> MacLinkPairing {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard status == errSecSuccess else { throw MacLinkError.randomFailed }
        return MacLinkPairing(id: UUID(), name: name, key: Data(bytes))
    }

    /// qrstudio-pair:1?id=…&name=…&key=… (clé en base64url).
    public var qrPayload: String {
        var components = URLComponents()
        components.scheme = Self.scheme
        components.path = "1"
        components.queryItems = [
            URLQueryItem(name: "id", value: id.uuidString),
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "key", value: Self.base64URL(key))
        ]
        return components.string ?? ""
    }

    public init?(qrPayload: String) {
        guard qrPayload.hasPrefix(Self.scheme + ":"),
              let components = URLComponents(string: qrPayload),
              let items = components.queryItems,
              let idText = items.first(where: { $0.name == "id" })?.value, let id = UUID(uuidString: idText),
              let name = items.first(where: { $0.name == "name" })?.value,
              let keyText = items.first(where: { $0.name == "key" })?.value,
              let key = Self.data(base64URL: keyText), key.count == 32 else { return nil }
        self.init(id: id, name: name, key: key)
    }

    static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func data(base64URL text: String) -> Data? {
        var base64 = text.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        return Data(base64Encoded: base64)
    }
}
