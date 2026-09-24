import Foundation

public struct ProductInfo: Sendable, Hashable {
    public init(code: String, gtin: String, manufacturerURL: URL? = nil) {
        self.code = code
        self.gtin = gtin
        self.manufacturerURL = manufacturerURL
    }

    /// Code tel que lu (8 à 14 chiffres).
    public var code: String
    /// GTIN normalisé sur 14 chiffres.
    public var gtin: String
    /// Page du fabricant quand le code vient d'un GS1 Digital Link.
    public var manufacturerURL: URL?

    public var isDigitalLink: Bool { manufacturerURL != nil }
    public var isChecksumValid: Bool { GTIN.isValid(code) }
    /// Code le plus court significatif, pour les recherches (EAN-13 plutôt que GTIN-14).
    public var searchCode: String {
        var trimmed = gtin
        while trimmed.count > 13, trimmed.hasPrefix("0") { trimmed.removeFirst() }
        return trimmed
    }
}
