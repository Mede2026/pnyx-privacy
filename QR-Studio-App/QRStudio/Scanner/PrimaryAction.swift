import Foundation
import QRCore

/// Action principale d'un type de contenu, déclenchable sans toucher la feuille.
enum PrimaryAction {
    case openURL(URL)
    case openMaps(GeoPoint)
    case call(String)
    case email(EmailMessage)
    case sms(SMSMessage)
    case copy(String)
    case productPage(URL)
}
