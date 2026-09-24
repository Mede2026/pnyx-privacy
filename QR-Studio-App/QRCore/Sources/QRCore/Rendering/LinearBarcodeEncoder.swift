import Foundation

/// Encodeurs maison des symbologies que Core Image ne génère pas.
enum LinearBarcodeEncoder {
    // Motifs EAN : L (parité impaire), G (paire), R (droite). 1 = barre.
    private static let lCodes = ["0001101", "0011001", "0010011", "0111101", "0100011",
                                 "0110001", "0101111", "0111011", "0110111", "0001011"]
    private static let gCodes = ["0100111", "0110011", "0011011", "0100001", "0011101",
                                 "0111001", "0000101", "0010001", "0001001", "0010111"]
    private static let rCodes = ["1110010", "1100110", "1101100", "1000010", "1011100",
                                 "1001110", "1010000", "1000100", "1001000", "1110100"]
    /// Parité des 6 chiffres de gauche d'un EAN-13, selon le premier chiffre.
    private static let parity = ["LLLLLL", "LLGLGG", "LLGGLG", "LLGGGL", "LGLLGG",
                                 "LGGLLG", "LGGGLL", "LGLGLG", "LGLGGL", "LGGLGL"]

    static func ean13(_ code: String) throws -> LinearSymbol {
        let d = try validatedGTIN(code, length: 13, symbology: .ean13)
        var bits = "101"
        let pattern = Array(parity[d[0]])
        for i in 1...6 {
            bits += pattern[i - 1] == "L" ? lCodes[d[i]] : gCodes[d[i]]
        }
        bits += "01010"
        for i in 7...12 { bits += rCodes[d[i]] }
        bits += "101"
        let modules = bits.map { $0 == "1" }
        let guards = guardMask(count: modules.count, ranges: [0..<3, 45..<50, 92..<95])
        let text = code.map(String.init)
        return LinearSymbol(
            modules: modules,
            guards: guards,
            captions: [
                .init(text: text[0], from: -9, to: -2),
                .init(text: text[1...6].joined(), from: 3, to: 45),
                .init(text: text[7...12].joined(), from: 50, to: 92)
            ],
            quietLeft: 11, quietRight: 7, digitsBetweenGuards: true
        )
    }

    /// UPC-A = EAN-13 précédé d'un zéro ; seule la présentation des chiffres change.
    static func upcA(_ code: String) throws -> LinearSymbol {
        _ = try validatedGTIN(code, length: 12, symbology: .upcA)
        var symbol = try ean13("0" + code)
        let text = code.map(String.init)
        // Le premier et le dernier caractère de données descendent comme les gardes.
        symbol.guards = guardMask(count: symbol.modules.count, ranges: [0..<10, 45..<50, 85..<95])
        symbol.captions = [
            .init(text: text[0], from: -8, to: -2, small: true),
            .init(text: text[1...5].joined(), from: 10, to: 45),
            .init(text: text[6...10].joined(), from: 50, to: 85),
            .init(text: text[11], from: 97, to: 103, small: true)
        ]
        symbol.quietLeft = 9
        symbol.quietRight = 9
        return symbol
    }

    static func ean8(_ code: String) throws -> LinearSymbol {
        let d = try validatedGTIN(code, length: 8, symbology: .ean8)
        var bits = "101"
        for i in 0...3 { bits += lCodes[d[i]] }
        bits += "01010"
        for i in 4...7 { bits += rCodes[d[i]] }
        bits += "101"
        let modules = bits.map { $0 == "1" }
        let text = code.map(String.init)
        return LinearSymbol(
            modules: modules,
            guards: guardMask(count: modules.count, ranges: [0..<3, 31..<36, 64..<67]),
            captions: [
                .init(text: text[0...3].joined(), from: 3, to: 31),
                .init(text: text[4...7].joined(), from: 36, to: 64)
            ],
            quietLeft: 7, quietRight: 7, digitsBetweenGuards: true
        )
    }

    // Code 39 : table binaire de référence (1 = barre), convertie en largeurs étroite/large.
    private static let code39Table: [Character: String] = [
        "0": "101001101101", "1": "110100101011", "2": "101100101011", "3": "110110010101",
        "4": "101001101011", "5": "110100110101", "6": "101100110101", "7": "101001011011",
        "8": "110100101101", "9": "101100101101", "A": "110101001011", "B": "101101001011",
        "C": "110110100101", "D": "101011001011", "E": "110101100101", "F": "101101100101",
        "G": "101010011011", "H": "110101001101", "I": "101101001101", "J": "101011001101",
        "K": "110101010011", "L": "101101010011", "M": "110110101001", "N": "101011010011",
        "O": "110101101001", "P": "101101101001", "Q": "101010110011", "R": "110101011001",
        "S": "101101011001", "T": "101011011001", "U": "110010101011", "V": "100110101011",
        "W": "110011010101", "X": "100101101011", "Y": "110010110101", "Z": "100110110101",
        "-": "100101011011", ".": "110010101101", " ": "100110101101", "*": "100101101101",
        "$": "100100100101", "/": "100100101001", "+": "100101001001", "%": "101001001001"
    ]

    static let code39Alphabet = Set(code39Table.keys.filter { $0 != "*" })

    /// Code 39 avec rapport large/étroit de 3, et un espace étroit entre les caractères.
    static func code39(_ text: String) throws -> LinearSymbol {
        let upper = text.uppercased()
        guard !upper.isEmpty, upper.allSatisfy(code39Alphabet.contains) else {
            throw RenderError.invalidContent(L("Le Code 39 n’accepte que A–Z, 0–9, l’espace et - . $ / + %."))
        }
        var modules: [Bool] = []
        for (index, character) in ("*" + upper + "*").enumerated() {
            if index > 0 { modules.append(false) }
            guard let binary = code39Table[character] else { continue }
            for run in runs(of: binary) {
                modules += Array(repeating: run.isBar, count: run.length == 1 ? 1 : 3)
            }
        }
        return LinearSymbol(
            modules: modules,
            guards: Array(repeating: false, count: modules.count),
            captions: [.init(text: upper, from: 0, to: Double(modules.count))],
            quietLeft: 10, quietRight: 10, digitsBetweenGuards: false
        )
    }

    /// Interleaved 2 of 5 : poids 1-2-4-7-parité ; les chiffres pairs en barres, impairs en espaces.
    private static let itfPatterns = ["nnwwn", "wnnnw", "nwnnw", "wwnnn", "nnwnw",
                                      "wnwnn", "nwwnn", "nnnww", "wnnwn", "nwnwn"]

    static func interleaved2of5(_ code: String, symbology: Symbology) throws -> LinearSymbol {
        guard let d = GTIN.digits(of: code), !d.isEmpty, d.count.isMultiple(of: 2) else {
            throw RenderError.invalidContent(L("L’ITF exige un nombre pair de chiffres."))
        }
        if symbology == .itf14 {
            _ = try validatedGTIN(code, length: 14, symbology: .itf14)
        }
        func width(_ c: Character) -> Int { c == "w" ? 3 : 1 }
        var modules: [Bool] = [true, false, true, false]
        for pair in stride(from: 0, to: d.count, by: 2) {
            let bars = Array(itfPatterns[d[pair]])
            let spaces = Array(itfPatterns[d[pair + 1]])
            for i in 0..<5 {
                modules += Array(repeating: true, count: width(bars[i]))
                modules += Array(repeating: false, count: width(spaces[i]))
            }
        }
        modules += [true, true, true, false, true]
        return LinearSymbol(
            modules: modules,
            guards: Array(repeating: false, count: modules.count),
            captions: [.init(text: code, from: 0, to: Double(modules.count))],
            quietLeft: 10, quietRight: 10, digitsBetweenGuards: false
        )
    }

    /// Code 128 : les modules viennent de Core Image, le texte est ajouté ici.
    static func code128(modules: [Bool], text: String) -> LinearSymbol {
        LinearSymbol(
            modules: modules,
            guards: Array(repeating: false, count: modules.count),
            captions: [.init(text: text, from: 0, to: Double(modules.count))],
            quietLeft: 10, quietRight: 10, digitsBetweenGuards: false
        )
    }

    // MARK: - Outils

    private static func validatedGTIN(_ code: String, length: Int, symbology: Symbology) throws -> [Int] {
        guard code.count == length, let digits = GTIN.digits(of: code) else {
            throw RenderError.invalidContent(
                String(format: L("%@ exige exactement %lld chiffres."), symbology.displayName, length)
            )
        }
        guard GTIN.isValid(code) else {
            let expected = GTIN.expectedCheckDigit(for: code) ?? 0
            throw RenderError.invalidContent(
                String(format: L("Somme de contrôle invalide : %lld attendu, %lld trouvé."), expected, digits.last ?? 0)
            )
        }
        return digits
    }

    private static func guardMask(count: Int, ranges: [Range<Int>]) -> [Bool] {
        var mask = Array(repeating: false, count: count)
        for range in ranges {
            for i in range where i < count { mask[i] = true }
        }
        return mask
    }

    private static func runs(of binary: String) -> [(isBar: Bool, length: Int)] {
        var result: [(Bool, Int)] = []
        for character in binary {
            let isBar = character == "1"
            if let last = result.last, last.0 == isBar {
                result[result.count - 1].1 += 1
            } else {
                result.append((isBar, 1))
            }
        }
        return result.map { (isBar: $0.0, length: $0.1) }
    }
}
