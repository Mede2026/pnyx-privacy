import Foundation

/// Score de pénalité des masques QR (quatre règles de la norme).
/// N'influe que sur la robustesse de lecture : tout masque produit un code valide.
enum QRPenalty {
    static func score(_ m: BitMatrix) -> Int {
        let size = m.width
        var score = 0

        // Règle 1 : suites de 5 modules ou plus de même couleur, en lignes et en colonnes.
        for horizontal in [true, false] {
            for a in 0..<size {
                var runColor = false
                var run = 0
                for b in 0..<size {
                    let dark = horizontal ? m[b, a] : m[a, b]
                    if b > 0, dark == runColor {
                        run += 1
                    } else {
                        if run >= 5 { score += 3 + (run - 5) }
                        runColor = dark
                        run = 1
                    }
                }
                if run >= 5 { score += 3 + (run - 5) }
            }
        }

        // Règle 2 : blocs 2 × 2 unis.
        for y in 0..<(size - 1) {
            for x in 0..<(size - 1) {
                let c = m[x, y]
                if c == m[x + 1, y], c == m[x, y + 1], c == m[x + 1, y + 1] { score += 3 }
            }
        }

        // Règle 3 : motifs semblables aux repères (1:1:3:1:1 bordé de 4 clairs).
        let patternA: [Bool] = [true, false, true, true, true, false, true, false, false, false, false]
        let patternB: [Bool] = Array(patternA.reversed())
        for horizontal in [true, false] {
            for a in 0..<size {
                for b in 0...(size - 11) {
                    var matchA = true
                    var matchB = true
                    for k in 0..<11 {
                        let dark = horizontal ? m[b + k, a] : m[a, b + k]
                        if dark != patternA[k] { matchA = false }
                        if dark != patternB[k] { matchB = false }
                        if !matchA && !matchB { break }
                    }
                    if matchA { score += 40 }
                    if matchB { score += 40 }
                }
            }
        }

        // Règle 4 : équilibre clair / sombre.
        let total = size * size
        let dark = m.darkCount
        let k = (abs(dark * 20 - total * 10) + total - 1) / total - 1
        score += max(0, k) * 10
        return score
    }
}
