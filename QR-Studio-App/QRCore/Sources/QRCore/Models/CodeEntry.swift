import Foundation
import SwiftData

/// Un code scanné ou généré.
///
/// Contraintes CloudKit : chaque propriété a une valeur par défaut ou est optionnelle,
/// aucune contrainte d'unicité, et toutes les relations sont optionnelles dans les deux sens.
@Model
public final class CodeEntry {
    public var id: UUID = UUID()
    public var rawValue: String = ""
    public var symbology: String = "qr"
    public var contentType: String = "text"
    public var origin: String = "scanned"
    public var createdAt: Date = Date()
    public var isFavorite: Bool = false
    public var note: String = ""
    public var label: String = ""
    public var latitude: Double?
    public var longitude: Double?
    /// Quantité comptée en mode lot.
    public var quantity: Int = 1
    /// Ajout à la spec : date de mise à la corbeille (nil = entrée active). Purge après 30 jours.
    public var deletedAt: Date?
    /// Ajout à la spec : code principal ouvert par la complication de la montre.
    public var isPrimary: Bool = false
    /// Ajout à la spec : GTIN sur 14 chiffres, que le produit vienne d'un code-barres ou d'un GS1 Digital Link.
    public var productCode: String?
    /// Ajout à la spec : nom du lieu obtenu par géocodage inverse, mis en cache.
    public var placeName: String?

    @Relationship(deleteRule: .cascade, inverse: \CodeStyle.entry)
    public var style: CodeStyle?

    @Relationship(inverse: \Folder.entries)
    public var folder: Folder?

    public init(
        rawValue: String,
        symbology: Symbology,
        contentType: ContentType,
        origin: Origin,
        createdAt: Date = .now
    ) {
        self.id = UUID()
        self.rawValue = rawValue
        self.symbology = symbology.rawValue
        self.contentType = contentType.rawValue
        self.origin = origin.rawValue
        self.createdAt = createdAt
    }

    public enum Origin: String, Codable, Sendable, CaseIterable {
        case scanned
        case generated
    }
}

public extension CodeEntry {
    var contentKind: ContentType {
        get { ContentType(storedValue: contentType) }
        set { contentType = newValue.rawValue }
    }

    var symbologyKind: Symbology {
        get { Symbology(storedValue: symbology) }
        set { symbology = newValue.rawValue }
    }

    var originKind: Origin {
        Origin(rawValue: origin) ?? .scanned
    }

    var isInTrash: Bool { deletedAt != nil }

    /// Titre affiché : le libellé s'il existe, sinon le type détecté.
    var displayTitle: String {
        label.isEmpty ? contentKind.title : label
    }

    /// Contenu lisible sur une ligne, pour une rangée de liste : le nom du réseau plutôt que la chaîne WIFI:
    /// (jamais le mot de passe), le nom d'un contact plutôt que sa vCard, le titre d'un événement.
    var summary: String {
        let readable: String = switch ScannedContentParser.parse(rawValue, symbology: symbologyKind) {
        case .wifi(let network): network.ssid
        case .contact(let card): [card.displayName, card.organization].filter { !$0.isEmpty }.joined(separator: " · ")
        case .event(let event): event.title
        case .email(let email): email.subject.isEmpty ? email.to : "\(email.to) · \(email.subject)"
        case .sms(let sms): sms.body.isEmpty ? sms.number : "\(sms.number) · \(sms.body)"
        case .location(let point): point.query ?? "\(point.latitude), \(point.longitude)"
        default: rawValue
        }
        let singleLine = (readable.isEmpty ? SecretRedactor.redacted(rawValue) : readable)
            .replacingOccurrences(of: "\r\n", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
        return String(singleLine.prefix(160))
    }
}
