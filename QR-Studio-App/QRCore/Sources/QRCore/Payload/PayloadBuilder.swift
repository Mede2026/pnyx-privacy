import Foundation

/// Assemble la chaîne exacte à encoder pour chaque type de contenu.
public enum PayloadBuilder {
    public static func build(_ input: PayloadInput) throws -> String {
        switch input {
        case .text(let text):
            guard !text.isEmpty else { throw PayloadError.empty }
            return text
        case .url(let text):
            return try url(text)
        case .wifi(let wifi):
            return try PayloadFormats.wifi(wifi)
        case .wifiEnterprise(let wifi):
            return try PayloadFormats.enterpriseWiFi(wifi)
        case .contact(let contact):
            return try PayloadFormats.vCard(contact)
        case .location(let latitude, let longitude):
            return try geo(latitude: latitude, longitude: longitude)
        case .email(let email):
            return try mailto(email)
        case .sms(let number, let message):
            // Format SMSTO:numéro:message
            return "SMSTO:\(try phoneNumber(number)):\(message)"
        case .phone(let number):
            return "tel:\(try phoneNumber(number))"
        case .event(let event):
            return try PayloadFormats.vEvent(event)
        case .social(let platform, let username):
            return try social(platform: platform, username: username)
        case .crypto(let network, let address, let amount):
            return try crypto(network: network, address: address, amount: amount)
        case .product(let code):
            return try product(code)
        }
    }

    // MARK: - Types simples

    /// Ajoute https:// si aucun schéma n'est présent.
    static func url(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw PayloadError.empty }
        guard !trimmed.contains(" ") else { throw PayloadError.invalidURL }
        let withScheme = trimmed.range(of: "://") == nil ? "https://" + trimmed : trimmed
        guard let components = URLComponents(string: withScheme),
              let host = components.host, host.contains("."), !host.hasPrefix("."), !host.hasSuffix(".") else {
            throw PayloadError.invalidURL
        }
        return withScheme
    }

    /// geo:latitude,longitude — toujours avec un point décimal.
    static func geo(latitude: Double, longitude: Double) throws -> String {
        guard (-90...90).contains(latitude), (-180...180).contains(longitude),
              latitude.isFinite, longitude.isFinite else { throw PayloadError.invalidCoordinates }
        return "geo:\(coordinate(latitude)),\(coordinate(longitude))"
    }

    public static func coordinate(_ value: Double) -> String {
        var text = String(format: "%.6f", value)
        while text.hasSuffix("0") { text.removeLast() }
        if text.hasSuffix(".") { text.removeLast() }
        return text == "-0" ? "0" : text
    }

    /// mailto:adresse?subject=…&body=… ; objet et corps encodés en pourcentage.
    static func mailto(_ email: EmailInput) throws -> String {
        let recipient = email.recipient.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isEmailAddress(recipient) else { throw PayloadError.invalidEmail }
        var parameters: [String] = []
        if !email.subject.isEmpty { parameters.append("subject=\(percentEncoded(email.subject))") }
        if !email.body.isEmpty { parameters.append("body=\(percentEncoded(email.body))") }
        return "mailto:\(recipient)" + (parameters.isEmpty ? "" : "?" + parameters.joined(separator: "&"))
    }

    static func isEmailAddress(_ text: String) -> Bool {
        let parts = text.split(separator: "@", omittingEmptySubsequences: false)
        return parts.count == 2 && !parts[0].isEmpty && parts[1].contains(".")
            && !text.contains(where: \.isWhitespace)
    }

    /// Garde le + initial et les chiffres ; retire espaces, tirets, points et parenthèses.
    static func phoneNumber(_ text: String) throws -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var result = trimmed.hasPrefix("+") ? "+" : ""
        for character in trimmed {
            if character.isASCII, character.isNumber {
                result.append(character)
            } else if !" -.()+/".contains(character) {
                throw PayloadError.invalidPhone
            }
        }
        guard result.filter(\.isNumber).count >= 3 else { throw PayloadError.invalidPhone }
        return result
    }

    static func social(platform: SocialPlatform, username: String) throws -> String {
        var name = username.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.lowercased().hasPrefix("http") { return try url(name) }
        while name.hasPrefix("@") { name.removeFirst() }
        guard !name.isEmpty, !name.contains(where: \.isWhitespace) else { throw PayloadError.empty }
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        let encoded = name.addingPercentEncoding(withAllowedCharacters: allowed) ?? name
        return platform.profileTemplate.replacingOccurrences(of: "{u}", with: encoded)
    }

    /// bitcoin:adresse?amount=0.01 (BIP 21). Ethereum suit EIP-681, montant en wei.
    static func crypto(network: CryptoNetwork, address: String, amount: String) throws -> String {
        var cleaned = address.trimmingCharacters(in: .whitespacesAndNewlines)
        if let range = cleaned.range(of: "\(network.rawValue):", options: [.caseInsensitive, .anchored]) {
            cleaned.removeSubrange(range)
        }
        guard !cleaned.isEmpty, cleaned.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) }) else {
            throw PayloadError.invalidAddress
        }
        let amountText = amount.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !amountText.isEmpty else { return "\(network.rawValue):\(cleaned)" }
        guard let value = Decimal(string: amountText, locale: Locale(identifier: "en_US_POSIX")),
              value > 0, amountText.allSatisfy({ $0.isNumber || $0 == "." }) else {
            throw PayloadError.invalidAmount
        }
        if network == .ethereum {
            let wei = value * Decimal(sign: .plus, exponent: 18, significand: 1)
            return "ethereum:\(cleaned)?value=\(NSDecimalNumber(decimal: wei).stringValue)"
        }
        return "\(network.rawValue):\(cleaned)?amount=\(amountText)"
    }

    /// Valeur brute d'un code produit, avec vérification de la somme de contrôle GS1.
    static func product(_ code: String) throws -> String {
        let digits = code.filter { !$0.isWhitespace && $0 != "-" }
        guard !digits.isEmpty else { throw PayloadError.empty }
        guard GTIN.digits(of: digits) != nil, [8, 12, 13, 14].contains(digits.count) else {
            throw PayloadError.invalidProductCode(L("Un code produit compte 8, 12, 13 ou 14 chiffres."))
        }
        guard GTIN.isValid(digits) else {
            let expected = GTIN.expectedCheckDigit(for: digits) ?? 0
            throw PayloadError.invalidProductCode(
                String(format: L("Somme de contrôle invalide : le dernier chiffre devrait être %lld."), expected)
            )
        }
        return digits
    }

    static func percentEncoded(_ text: String) -> String {
        let unreserved = CharacterSet(charactersIn:
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return text.addingPercentEncoding(withAllowedCharacters: unreserved) ?? text
    }
}
