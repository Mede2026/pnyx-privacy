import Foundation

/// Base ouverte, gratuite et sans clé : permet d'afficher le nom du produit dans la fiche.
/// Appelée seulement à la demande de l'utilisateur ou si les aperçus en ligne sont activés.
enum OpenFoodFactsClient {
    struct Product: Decodable, Sendable {
        var productName: String?
        var brands: String?

        enum CodingKeys: String, CodingKey {
            case productName = "product_name"
            case brands
        }

        var displayName: String? {
            let parts = [productName, brands].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            return parts.isEmpty ? nil : parts.joined(separator: " — ")
        }
    }

    private struct Response: Decodable {
        var status: Int
        var product: Product?
    }

    enum LookupError: LocalizedError {
        case notFound

        var errorDescription: String? {
            String(localized: "Ce produit n’est pas encore dans Open Food Facts.")
        }
    }

    static func lookup(code: String) async throws -> Product {
        guard let encoded = code.addingPercentEncoding(withAllowedCharacters: .alphanumerics),
              let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(encoded).json?fields=product_name,brands")
        else { throw LookupError.notFound }
        var request = URLRequest(url: url, timeoutInterval: 10)
        request.setValue("QRStudio/1.0 (iOS; free app)", forHTTPHeaderField: "User-Agent")
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(Response.self, from: data)
        guard response.status == 1, let product = response.product, product.displayName != nil else {
            throw LookupError.notFound
        }
        return product
    }
}
