import Foundation

/// Tables de la norme ISO/IEC 18004 (QR modèle 2), indexées par version (1 à 40).
/// L'index 0 est inutilisé. Ordre des niveaux : L, M, Q, H.
enum QRTables {
    static let eccCodewordsPerBlock: [[Int]] = [
        [-1, 7, 10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24, 26, 30, 22, 24, 28, 30, 28, 28,
         28, 28, 30, 30, 26, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
        [-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26,
         26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28],
        [-1, 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26, 24, 20, 30, 24, 28, 28, 26, 30,
         28, 30, 30, 30, 30, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
        [-1, 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28, 22, 24, 24, 30, 28, 28, 26, 28,
         30, 24, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30]
    ]

    static let errorCorrectionBlocks: [[Int]] = [
        [-1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 4, 6, 6, 6, 6, 7, 8,
         8, 9, 9, 10, 12, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 24, 25],
        [-1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16,
         17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49],
        [-1, 1, 1, 2, 2, 4, 4, 6, 6, 8, 8, 8, 10, 12, 16, 12, 17, 16, 18, 21, 20,
         23, 23, 25, 27, 29, 34, 34, 35, 38, 40, 43, 45, 48, 51, 53, 56, 59, 62, 65, 68],
        [-1, 1, 1, 2, 4, 4, 4, 5, 6, 8, 8, 11, 11, 16, 16, 18, 16, 19, 21, 25, 25,
         25, 34, 30, 32, 35, 37, 40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 70, 74, 77, 81]
    ]

    static func levelIndex(_ level: ErrorCorrection) -> Int {
        switch level {
        case .L: 0
        case .M: 1
        case .Q: 2
        case .H: 3
        }
    }

    /// Bits de niveau inscrits dans l'information de format (L=01, M=00, Q=11, H=10).
    static func formatBits(_ level: ErrorCorrection) -> Int {
        switch level {
        case .L: 1
        case .M: 0
        case .Q: 3
        case .H: 2
        }
    }

    /// Nombre de modules disponibles pour les données et la correction, hors motifs fixes.
    static func rawDataModules(version: Int) -> Int {
        var result = (16 * version + 128) * version + 64
        if version >= 2 {
            let alignCount = version / 7 + 2
            result -= (25 * alignCount - 10) * alignCount - 55
            if version >= 7 { result -= 36 }
        }
        return result
    }

    static func dataCodewords(version: Int, level: ErrorCorrection) -> Int {
        let i = levelIndex(level)
        return rawDataModules(version: version) / 8
            - eccCodewordsPerBlock[i][version] * errorCorrectionBlocks[i][version]
    }

    static func alignmentPositions(version: Int) -> [Int] {
        guard version > 1 else { return [] }
        let count = version / 7 + 2
        let size = version * 4 + 17
        let step = (version * 8 + count * 3 + 5) / (count * 4 - 4) * 2
        var result = [6]
        var position = size - 7
        var tail: [Int] = []
        for _ in 0..<(count - 1) {
            tail.insert(position, at: 0)
            position -= step
        }
        result += tail
        return result
    }
}
