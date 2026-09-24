import Foundation

/// Contenu décodé et structuré selon son type.
public enum ParsedContent: Sendable, Hashable {
    case text(String)
    case url(URL)
    case wifi(WiFiNetwork)
    case contact(ContactCard)
    case location(GeoPoint)
    case email(EmailMessage)
    case sms(SMSMessage)
    case phone(String)
    case event(CalendarEvent)
    case product(ProductInfo)
    case crypto(CryptoPayment)

    public var contentType: ContentType {
        switch self {
        case .text: .text
        case .url: .url
        case .wifi(let network): network.isEnterprise ? .wifiEnterprise : .wifi
        case .contact: .contact
        case .location: .location
        case .email: .email
        case .sms: .sms
        case .phone: .phone
        case .event: .event
        case .product: .product
        case .crypto: .crypto
        }
    }

    /// Actions dont les conséquences sont difficiles à annuler : toujours une confirmation.
    public var requiresConfirmation: Bool {
        switch self {
        case .wifi, .contact, .event, .crypto: true
        default: false
        }
    }
}
