import Foundation
import Security

public enum MacLinkError: LocalizedError {
    case randomFailed
    case keychain(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .randomFailed: L("La clé d’appairage n’a pas pu être créée.")
        case .keychain: L("Le trousseau n’a pas pu enregistrer l’appairage.")
        }
    }
}
