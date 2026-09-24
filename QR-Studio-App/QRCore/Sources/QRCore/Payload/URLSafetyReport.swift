import Foundation

/// Analyse locale d'une URL avant ouverture : l'utilisateur doit toujours voir où il va.
public struct URLSafetyReport: Sendable, Equatable {
    public enum Warning: Sendable, Hashable {
        /// Lien en http : la connexion n'est pas chiffrée.
        case notEncrypted
        /// Domaine contenant des caractères non latins ou du punycode (xn--) : risque d'imitation.
        case deceptiveCharacters(decodedHost: String)
        /// Raccourcisseur : la vraie destination est cachée.
        case shortener
        /// Adresse IP au lieu d'un nom de domaine.
        case ipAddress
        /// Identifiants avant le domaine (https://banque.com@pirate.net).
        case embeddedCredentials
        /// Lien de paiement : demande toujours une confirmation.
        case payment
    }

    public var host: String
    public var displayHost: String
    public var path: String
    public var queryItems: [URLQueryItem]
    public var warnings: [Warning]

    public var isPayment: Bool { warnings.contains(.payment) }
    public var hasWarnings: Bool { !warnings.isEmpty }
}
