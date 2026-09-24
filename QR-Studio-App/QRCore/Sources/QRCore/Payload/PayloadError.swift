import Foundation

public enum PayloadError: LocalizedError, Equatable, Sendable {
    case empty
    case invalidURL
    case invalidEmail
    case invalidPhone
    case invalidCoordinates
    case invalidDates
    case invalidAmount
    case invalidAddress
    case invalidProductCode(String)

    public var errorDescription: String? {
        switch self {
        case .empty: L("Remplissez les champs obligatoires.")
        case .invalidURL: L("Cette adresse web n’est pas valide.")
        case .invalidEmail: L("Cette adresse courriel n’est pas valide.")
        case .invalidPhone: L("Ce numéro de téléphone n’est pas valide.")
        case .invalidCoordinates: L("La latitude doit être entre -90 et 90, la longitude entre -180 et 180.")
        case .invalidDates: L("La fin doit venir après le début.")
        case .invalidAmount: L("Le montant n’est pas un nombre valide.")
        case .invalidAddress: L("L’adresse du portefeuille n’est pas valide.")
        case .invalidProductCode(let message): message
        }
    }
}
