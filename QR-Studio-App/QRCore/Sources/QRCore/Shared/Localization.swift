import Foundation

/// Textes d'interface fournis par QRCore, lus dans le catalogue du package.
@inline(__always)
func L(_ key: String.LocalizationValue) -> String {
    String(localized: key, bundle: .module)
}
