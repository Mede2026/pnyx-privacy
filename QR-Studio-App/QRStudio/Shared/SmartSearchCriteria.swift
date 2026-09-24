import Foundation
import FoundationModels

/// Critères extraits d'une phrase par le modèle embarqué. Le modèle traduit l'intention ;
/// c'est la requête SwiftData qui filtre, jamais le modèle.
@available(iOS 26.0, macOS 26.0, *)
@Generable
struct SmartSearchCriteria {
    @Guide(description: "Words to look for in the code content, note or label; empty if none")
    let keywords: String

    @Guide(description: "One of: text, url, wifi, vcard, geo, email, sms, phone, event, wifiEnterprise, social, crypto, product; or empty")
    let contentType: String

    @Guide(description: "Start of the period as yyyy-MM-dd, or empty")
    let startDate: String

    @Guide(description: "End of the period as yyyy-MM-dd, or empty")
    let endDate: String

    @Guide(description: "True only if the user asks for favorites")
    let favoritesOnly: Bool
}
