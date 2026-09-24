import Foundation

/// Contenu à encoder, avec les champs propres à chaque type.
public enum PayloadInput: Sendable, Hashable {
    case text(String)
    case url(String)
    case wifi(WiFiInput)
    case contact(ContactInput)
    case location(latitude: Double, longitude: Double)
    case email(EmailInput)
    case sms(number: String, message: String)
    case phone(String)
    case event(EventInput)
    case wifiEnterprise(EnterpriseWiFiInput)
    case social(platform: SocialPlatform, username: String)
    case crypto(network: CryptoNetwork, address: String, amount: String)
    case product(String)

    public var contentType: ContentType {
        switch self {
        case .text: .text
        case .url: .url
        case .wifi: .wifi
        case .contact: .contact
        case .location: .location
        case .email: .email
        case .sms: .sms
        case .phone: .phone
        case .event: .event
        case .wifiEnterprise: .wifiEnterprise
        case .social: .social
        case .crypto: .crypto
        case .product: .product
        }
    }
}
