import Foundation

/// Code 128 en Swift pur, pour watchOS où Core Image n'existe pas.
/// Jeu B pour le texte, jeu C pour les suites de chiffres (deux chiffres par symbole), jeu A pour les caractères de contrôle.
enum Code128Encoder {
    /// Largeurs barre/espace des 107 symboles (valeurs 0 à 106) ; 103 à 105 : départs A, B, C ; 106 : arrêt.
    static let patterns: [String] = [
        "212222", "222122", "222221", "121223", "121322", "131222", "122213", "122312", "132212", "221213",
        "221312", "231212", "112232", "122132", "122231", "113222", "123122", "123221", "223211", "221132",
        "221231", "213212", "223112", "312131", "311222", "321122", "321221", "312212", "322112", "322211",
        "212123", "212321", "232121", "111323", "131123", "131321", "112313", "132113", "132311", "211313",
        "231113", "231311", "112133", "112331", "132131", "113123", "113321", "133121", "313121", "211331",
        "231131", "213113", "213311", "213131", "311123", "311321", "331121", "312113", "312311", "332111",
        "314111", "221411", "431111", "111224", "111422", "121124", "121421", "141122", "141221", "112214",
        "112412", "122114", "122411", "142112", "142211", "241211", "221114", "413111", "241112", "134111",
        "111242", "121142", "121241", "114212", "124112", "124211", "411212", "421112", "421211", "212141",
        "214121", "412121", "111143", "111341", "131141", "114113", "114311", "411113", "411311", "113141",
        "114131", "311141", "411131", "211412", "211214", "211232", "2331112"
    ]

    private enum CodeSet { case a, b, c }

    private static let startCodes: [CodeSet: Int] = [.a: 103, .b: 104, .c: 105]
    /// Symbole de bascule vers un jeu, identique quel que soit le jeu de départ.
    private static let switchCodes: [CodeSet: Int] = [.a: 101, .b: 100, .c: 99]

    /// Modules noirs (true) et blancs, sans zone silencieuse.
    static func modules(for text: String) throws -> [Bool] {
        let bytes = Array(text.utf8)
        guard !bytes.isEmpty, bytes.allSatisfy({ $0 < 128 }) else {
            throw RenderError.invalidContent(L("Le Code 128 n’accepte que les caractères ASCII."))
        }
        var values: [Int] = []
        var index = 0
        var current: CodeSet = digitRun(bytes, from: 0) >= 4 ? .c : (bytes[0] < 32 ? .a : .b)
        values.append(startCodes[current] ?? 104)

        while index < bytes.count {
            if current == .c {
                if digitRun(bytes, from: index) >= 2 {
                    values.append(Int(bytes[index] - 48) * 10 + Int(bytes[index + 1] - 48))
                    index += 2
                    continue
                }
                current = bytes[index] < 32 ? .a : .b
                values.append(switchCodes[current] ?? 100)
                continue
            }
            // Une suite d'au moins 4 chiffres (paire) passe en jeu C ; un chiffre impair part d'abord seul.
            let run = digitRun(bytes, from: index)
            if run >= 4 {
                if run % 2 == 1 {
                    values.append(Int(bytes[index]) - 32)
                    index += 1
                }
                current = .c
                values.append(switchCodes[.c] ?? 99)
                continue
            }
            let byte = bytes[index]
            if byte < 32 && current == .b {
                current = .a
                values.append(switchCodes[.a] ?? 101)
            } else if byte >= 96 && current == .a {
                current = .b
                values.append(switchCodes[.b] ?? 100)
            }
            values.append(byte < 32 ? Int(byte) + 64 : Int(byte) - 32)
            index += 1
        }

        // Somme de contrôle : départ + somme des valeurs pondérées par leur position, modulo 103.
        let checksum = values.enumerated().reduce(0) { sum, item in
            sum + item.element * max(item.offset, 1)
        } % 103
        values.append(checksum)
        values.append(106)
        return values.flatMap { widths(patterns[$0]) }
    }

    private static func digitRun(_ bytes: [UInt8], from start: Int) -> Int {
        var count = 0
        while start + count < bytes.count, (48...57).contains(bytes[start + count]) { count += 1 }
        return count
    }

    private static func widths(_ pattern: String) -> [Bool] {
        pattern.enumerated().flatMap { index, width in
            Array(repeating: index % 2 == 0, count: width.wholeNumberValue ?? 1)
        }
    }
}
