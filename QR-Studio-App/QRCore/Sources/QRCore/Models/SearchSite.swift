import Foundation
import SwiftData

/// Site de recherche de produit : un modèle d'URL contenant le jeton {code}.
/// Stocké dans SwiftData pour être synchronisé, comme demandé par la spec.
@Model
public final class SearchSite {
    public var id: UUID = UUID()
    public var name: String = ""
    public var urlTemplate: String = ""
    public var sortOrder: Int = 0
    public var isEnabled: Bool = true
    public var isBuiltIn: Bool = false

    public init(name: String, urlTemplate: String, sortOrder: Int, isBuiltIn: Bool = false) {
        self.id = UUID()
        self.name = name
        self.urlTemplate = urlTemplate
        self.sortOrder = sortOrder
        self.isBuiltIn = isBuiltIn
    }

    public static let codeToken = "{code}"

    /// URL de recherche pour un code donné, ou nil si le modèle est invalide.
    public func url(for code: String) -> URL? {
        SearchSite.resolve(template: urlTemplate, code: code)
    }

    public static func resolve(template: String, code: String) -> URL? {
        guard template.contains(codeToken) else { return nil }
        let encoded = code.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? code
        let text = template.replacingOccurrences(of: codeToken, with: encoded)
        guard let url = URL(string: text), let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http" else { return nil }
        return url
    }

    /// Sites installés par défaut.
    public static let defaults: [(name: String, template: String)] = [
        ("Open Food Facts", "https://world.openfoodfacts.org/product/{code}"),
        ("Google", "https://www.google.com/search?q={code}"),
        ("Amazon.ca", "https://www.amazon.ca/s?k={code}")
    ]
}
