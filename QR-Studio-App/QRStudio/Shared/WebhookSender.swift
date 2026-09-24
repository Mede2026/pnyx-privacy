import Foundation
import OSLog
import QRCore

/// Mode webhook (désactivé par défaut) : chaque scan part en POST JSON vers l'adresse choisie par l'utilisateur.
/// Seule requête de ce genre dans l'app, et seulement si l'utilisateur l'a configurée lui-même.
@MainActor
final class WebhookSender {
    enum WebhookError: LocalizedError {
        case invalidAddress
        case rejected(Int)

        var errorDescription: String? {
            switch self {
            case .invalidAddress:
                String(localized: "Adresse invalide. Utilisez https://, ou http:// seulement sur le réseau local.")
            case .rejected(let status):
                String(localized: "Le serveur a répondu avec le code \(status).")
            }
        }
    }

    struct Body: Encodable {
        let contenu: String
        let symbologie: String
        let type: String
        let date: Date
        let source = "QR Studio"
    }

    private let settings: AppSettings

    init(settings: AppSettings) {
        self.settings = settings
    }

    /// Envoi après un scan ; une erreur est journalisée sans interrompre le scan.
    func scanned(_ payload: String, symbology: Symbology) {
        guard settings.webhookEnabled, let url = Self.validatedURL(settings.webhookURL) else { return }
        let body = Body(contenu: payload, symbologie: symbology.rawValue,
                        type: ScannedContentParser.parse(payload, symbology: symbology).contentType.rawValue, date: .now)
        Task {
            do {
                try await Self.post(body, to: url)
            } catch {
                Logger.general.error("Webhook en échec : \(error.localizedDescription)")
            }
        }
    }

    /// Bouton « Envoyer un essai » des réglages.
    func sendTest() async throws {
        guard let url = Self.validatedURL(settings.webhookURL) else { throw WebhookError.invalidAddress }
        try await Self.post(Body(contenu: String(localized: "Essai de QR Studio"), symbologie: Symbology.qr.rawValue,
                                 type: ContentType.text.rawValue, date: .now), to: url)
    }

    /// https partout ; http toléré pour une adresse du réseau local (ex. un Raspberry Pi à la maison).
    static func validatedURL(_ text: String) -> URL? {
        guard let url = URL(string: text.trimmingCharacters(in: .whitespaces)), let host = url.host(), !host.isEmpty else {
            return nil
        }
        switch url.scheme?.lowercased() {
        case "https": return url
        case "http": return isLocal(host) ? url : nil
        default: return nil
        }
    }

    /// Réseaux privés (RFC 1918), boucle locale et noms Bonjour en .local.
    private static func isLocal(_ host: String) -> Bool {
        let parts = host.split(separator: ".").compactMap { Int($0) }
        if parts.count == 4 {
            return parts[0] == 10 || parts[0] == 127 || (parts[0] == 192 && parts[1] == 168)
                || (parts[0] == 172 && (16...31).contains(parts[1]))
        }
        return host.hasSuffix(".local") || host == "localhost"
    }

    private static func post(_ body: Body, to url: URL) async throws {
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try encoder.encode(body)
        let (_, response) = try await URLSession.shared.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw WebhookError.rejected(http.statusCode)
        }
    }
}
