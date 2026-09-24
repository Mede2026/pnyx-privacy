import Foundation

/// Outils GS1 : somme de contrôle, normalisation sur 14 chiffres, pays d'enregistrement.
public enum GTIN {
    /// Chiffre de contrôle GS1 : depuis la droite, poids 3 puis 1 en alternance.
    /// `digits` ne contient PAS le chiffre de contrôle.
    public static func checkDigit(for digits: [Int]) -> Int {
        var sum = 0
        for (index, digit) in digits.reversed().enumerated() {
            sum += digit * (index.isMultiple(of: 2) ? 3 : 1)
        }
        return (10 - sum % 10) % 10
    }

    public static func digits(of text: String) -> [Int]? {
        let values = text.compactMap(\.wholeNumberValue)
        guard values.count == text.count, text.allSatisfy(\.isASCII) else { return nil }
        return values
    }

    /// Vrai si la chaîne est un GTIN-8, 12, 13 ou 14 dont la somme de contrôle est juste.
    public static func isValid(_ code: String) -> Bool {
        guard [8, 12, 13, 14].contains(code.count), let digits = digits(of: code),
              let last = digits.last else { return false }
        return checkDigit(for: Array(digits.dropLast())) == last
    }

    /// Chiffre de contrôle attendu pour un code complet (dernier chiffre ignoré).
    public static func expectedCheckDigit(for code: String) -> Int? {
        guard let digits = digits(of: code), digits.count >= 2 else { return nil }
        return checkDigit(for: Array(digits.dropLast()))
    }

    /// GTIN sur 14 chiffres, avec des zéros en tête.
    public static func normalized(_ code: String) -> String? {
        guard let digits = digits(of: code), (8...14).contains(digits.count) else { return nil }
        return String(repeating: "0", count: 14 - digits.count) + code
    }

    /// UPC-E (8 chiffres : système, 6 chiffres, contrôle) développé en UPC-A (12 chiffres).
    public static func expandUPCE(_ code: String) -> String? {
        guard let d = digits(of: code), d.count == 8, d[0] == 0 || d[0] == 1 else { return nil }
        let ns = d[0], x = Array(d[1...6]), check = d[7]
        let body: [Int]
        switch x[5] {
        case 0, 1, 2: body = [x[0], x[1], x[5], 0, 0, 0, 0, x[2], x[3], x[4]]
        case 3: body = [x[0], x[1], x[2], 0, 0, 0, 0, 0, x[3], x[4]]
        case 4: body = [x[0], x[1], x[2], x[3], 0, 0, 0, 0, 0, x[4]]
        default: body = [x[0], x[1], x[2], x[3], x[4], 0, 0, 0, 0, x[5]]
        }
        return ([ns] + body + [check]).map(String.init).joined()
    }

    /// Code affiché par groupes, pour la lecture humaine.
    public static func formatted(_ code: String) -> String {
        let c = Array(code)
        func group(_ ranges: [Range<Int>]) -> String {
            ranges.map { String(c[$0]) }.joined(separator: " ")
        }
        switch c.count {
        case 13: return group([0..<1, 1..<7, 7..<13])
        case 12: return group([0..<1, 1..<6, 6..<11, 11..<12])
        case 8: return group([0..<4, 4..<8])
        case 14: return group([0..<1, 1..<3, 3..<8, 8..<13, 13..<14])
        default: return code
        }
    }

    /// Pays où l'entreprise a enregistré son préfixe GS1 (pas le pays de fabrication).
    public static func registrationCountry(for code: String) -> String? {
        guard let normalized = normalized(code) else { return nil }
        // Sur 14 chiffres, le préfixe GS1 commence au 2e chiffre (après l'indicateur).
        let start = normalized.index(normalized.startIndex, offsetBy: 1)
        guard let prefix = Int(normalized[start..<normalized.index(start, offsetBy: 3)]) else { return nil }
        switch prefix {
        case 0...139: return L("États-Unis et Canada")
        case 300...379: return L("France")
        case 400...440: return L("Allemagne")
        case 450...459, 490...499: return L("Japon")
        case 500...509: return L("Royaume-Uni")
        case 690...699: return L("Chine")
        case 754...755: return L("Canada")
        default: return nil
        }
    }
}
