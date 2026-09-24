import Foundation
import Observation
import QRCore

/// État des champs du générateur, pour tous les types. L'utilisateur ne tape jamais la syntaxe :
/// la chaîne exacte est assemblée par PayloadBuilder.
@MainActor
@Observable
final class GeneratorFormModel {
    let type: ContentType
    var symbology: Symbology
    var style = StyleConfig()
    var label = ""

    var text = ""
    var url = ""
    var wifi = WiFiInput()
    var enterpriseWiFi = EnterpriseWiFiInput()
    var contact = ContactInput()
    var latitude = ""
    var longitude = ""
    var email = EmailInput()
    var smsNumber = ""
    var smsMessage = ""
    var phone = ""
    var event = EventInput()
    var socialPlatform: SocialPlatform = .instagram
    var socialUsername = ""
    var cryptoNetwork: CryptoNetwork = .bitcoin
    var cryptoAddress = ""
    var cryptoAmount = ""
    var productCode = ""

    init(type: ContentType, prefill: String? = nil) {
        self.type = type
        self.symbology = type.generatableSymbologies.first ?? .qr
        guard let prefill else { return }
        switch type {
        case .url: url = prefill
        case .text: text = prefill
        case .product: productCode = prefill
        default: break
        }
    }

    var input: PayloadInput {
        switch type {
        case .text: .text(text)
        case .url: .url(url)
        case .wifi: .wifi(wifi)
        case .wifiEnterprise: .wifiEnterprise(enterpriseWiFi)
        case .contact: .contact(contact)
        case .location: .location(latitude: Self.number(latitude) ?? .nan, longitude: Self.number(longitude) ?? .nan)
        case .email: .email(email)
        case .sms: .sms(number: smsNumber, message: smsMessage)
        case .phone: .phone(phone)
        case .event: .event(event)
        case .social: .social(platform: socialPlatform, username: socialUsername)
        case .crypto: .crypto(network: cryptoNetwork, address: cryptoAddress, amount: cryptoAmount)
        case .product: .product(productCode)
        }
    }

    /// Résultat de l'assemblage : la chaîne à encoder, ou l'erreur à montrer.
    var payload: Result<String, PayloadError> {
        do {
            return .success(try PayloadBuilder.build(input))
        } catch let error as PayloadError {
            return .failure(error)
        } catch {
            return .failure(.empty)
        }
    }

    var hasContent: Bool {
        switch type {
        case .text: !text.isEmpty
        case .url: !url.isEmpty
        case .wifi: !wifi.ssid.isEmpty
        case .wifiEnterprise: !enterpriseWiFi.ssid.isEmpty
        case .contact: !(contact.firstName + contact.lastName + contact.organization).isEmpty
        case .location: !latitude.isEmpty || !longitude.isEmpty
        case .email: !email.recipient.isEmpty
        case .sms: !smsNumber.isEmpty
        case .phone: !phone.isEmpty
        case .event: !event.title.isEmpty
        case .social: !socialUsername.isEmpty
        case .crypto: !cryptoAddress.isEmpty
        case .product: !productCode.isEmpty
        }
    }

    /// Le code produit choisit sa symbologie selon sa longueur.
    func adjustProductSymbology() {
        guard type == .product else { return }
        let digits = productCode.filter(\.isNumber)
        switch digits.count {
        case 8: symbology = .ean8
        case 12: symbology = .upcA
        case 13: symbology = .ean13
        case 14: symbology = .itf14
        default: break
        }
    }

    var request: RenderRequest? {
        guard hasContent, case .success(let payload) = payload else { return nil }
        return RenderRequest(payload: payload, symbology: symbology, style: symbology.supportsFullStyling ? style : colorOnly)
    }

    /// Hors QR, seules les couleurs du style s'appliquent.
    private var colorOnly: StyleConfig {
        var config = StyleConfig()
        config.foreground = style.foreground
        config.background = style.background
        return config
    }

    /// Nombre saisi avec virgule ou point.
    static func number(_ text: String) -> Double? {
        Double(text.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
    }
}
