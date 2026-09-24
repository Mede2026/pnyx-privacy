import Foundation

/// Les 13 types de contenu que l'app sait générer et reconnaître.
public enum ContentType: String, CaseIterable, Codable, Sendable, Identifiable {
    case text
    case url
    case wifi
    case contact = "vcard"
    case location = "geo"
    case email
    case sms
    case phone
    case event
    case wifiEnterprise
    case social
    case crypto
    case product

    public var id: String { rawValue }

    public init(storedValue: String) {
        self = ContentType(rawValue: storedValue) ?? .text
    }

    public var symbolName: String {
        switch self {
        case .text: "text.alignleft"
        case .url: "link"
        case .wifi: "wifi"
        case .contact: "person.crop.rectangle"
        case .location: "mappin.and.ellipse"
        case .email: "envelope"
        case .sms: "message"
        case .phone: "phone"
        case .event: "calendar"
        case .wifiEnterprise: "lock.shield"
        case .social: "person.2"
        case .crypto: "bitcoinsign.circle"
        case .product: "barcode"
        }
    }

    public var title: String {
        switch self {
        case .text: L("Texte")
        case .url: L("Lien web")
        case .wifi: L("Wi-Fi")
        case .contact: L("Contact")
        case .location: L("Localisation")
        case .email: L("Courriel")
        case .sms: L("SMS")
        case .phone: L("Téléphone")
        case .event: L("Événement")
        case .wifiEnterprise: L("Wi-Fi entreprise")
        case .social: L("Réseau social")
        case .crypto: L("Crypto")
        case .product: L("Code-barres produit")
        }
    }

    /// Symbologies proposées dans le générateur pour ce type, la première étant le défaut.
    public var generatableSymbologies: [Symbology] {
        switch self {
        case .product: [.ean13, .ean8, .upcA, .itf14]
        case .text: [.qr, .aztec, .pdf417, .code128, .code39]
        case .url, .email, .sms, .phone, .social, .crypto: [.qr, .aztec, .pdf417, .code128]
        case .wifi, .wifiEnterprise, .contact, .location, .event: [.qr, .aztec, .pdf417]
        }
    }
}
