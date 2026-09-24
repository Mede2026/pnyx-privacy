import Foundation

/// Placement des modules dans la grille.
struct Builder {
    let version: Int
    let level: ErrorCorrection
    let size: Int
    var modules: BitMatrix
    var isFunction: BitMatrix

    init(version: Int, level: ErrorCorrection) {
        self.version = version
        self.level = level
        self.size = version * 4 + 17
        self.modules = BitMatrix(width: size, height: size)
        self.isFunction = BitMatrix(width: size, height: size)
    }

    mutating func set(_ x: Int, _ y: Int, _ dark: Bool) {
        modules[x, y] = dark
        isFunction[x, y] = true
    }

    mutating func drawFunctionPatterns() {
        for i in 0..<size {
            set(6, i, i.isMultiple(of: 2))
            set(i, 6, i.isMultiple(of: 2))
        }
        drawFinder(3, 3)
        drawFinder(size - 4, 3)
        drawFinder(3, size - 4)
        let positions = QRTables.alignmentPositions(version: version)
        let last = positions.count - 1
        for (i, x) in positions.enumerated() {
            for (j, y) in positions.enumerated() {
                if (i == 0 && j == 0) || (i == 0 && j == last) || (i == last && j == 0) { continue }
                for dy in -2...2 {
                    for dx in -2...2 { set(x + dx, y + dy, max(abs(dx), abs(dy)) != 1) }
                }
            }
        }
        drawFormatBits(mask: 0)
        drawVersion()
    }

    mutating func drawFinder(_ x: Int, _ y: Int) {
        for dy in -4...4 {
            for dx in -4...4 {
                let distance = max(abs(dx), abs(dy))
                let xx = x + dx, yy = y + dy
                if xx >= 0, xx < size, yy >= 0, yy < size {
                    set(xx, yy, distance != 2 && distance != 4)
                }
            }
        }
    }

    /// Information de format : niveau + masque, protégée par un code BCH (15, 5).
    mutating func drawFormatBits(mask: Int) {
        let data = QRTables.formatBits(level) << 3 | mask
        var remainder = data
        for _ in 0..<10 { remainder = (remainder << 1) ^ ((remainder >> 9) * 0x537) }
        let bits = (data << 10 | remainder) ^ 0x5412
        func bit(_ i: Int) -> Bool { (bits >> i) & 1 == 1 }

        for i in 0...5 { set(8, i, bit(i)) }
        set(8, 7, bit(6))
        set(8, 8, bit(7))
        set(7, 8, bit(8))
        for i in 9..<15 { set(14 - i, 8, bit(i)) }
        for i in 0..<8 { set(size - 1 - i, 8, bit(i)) }
        for i in 8..<15 { set(8, size - 15 + i, bit(i)) }
        set(8, size - 8, true)
    }

    /// Information de version (7 et plus), protégée par un code BCH (18, 6).
    mutating func drawVersion() {
        guard version >= 7 else { return }
        var remainder = version
        for _ in 0..<12 { remainder = (remainder << 1) ^ ((remainder >> 11) * 0x1F25) }
        let bits = version << 12 | remainder
        for i in 0..<18 {
            let dark = (bits >> i) & 1 == 1
            let a = size - 11 + i % 3
            let b = i / 3
            set(a, b, dark)
            set(b, a, dark)
        }
    }

    /// Parcours en zigzag par colonnes de deux, de droite à gauche.
    mutating func drawCodewords(_ data: [UInt8]) {
        var bitIndex = 0
        var right = size - 1
        while right >= 1 {
            if right == 6 { right = 5 }
            for vertical in 0..<size {
                for j in 0..<2 {
                    let x = right - j
                    let upward = (right + 1) & 2 == 0
                    let y = upward ? size - 1 - vertical : vertical
                    if !isFunction[x, y], bitIndex < data.count * 8 {
                        modules[x, y] = (data[bitIndex >> 3] >> UInt8(7 - (bitIndex & 7))) & 1 == 1
                        bitIndex += 1
                    }
                }
            }
            right -= 2
        }
    }

    mutating func applyMask(_ mask: Int) {
        for y in 0..<size {
            for x in 0..<size where !isFunction[x, y] {
                let invert: Bool
                switch mask {
                case 0: invert = (x + y) % 2 == 0
                case 1: invert = y % 2 == 0
                case 2: invert = x % 3 == 0
                case 3: invert = (x + y) % 3 == 0
                case 4: invert = (x / 3 + y / 2) % 2 == 0
                case 5: invert = x * y % 2 + x * y % 3 == 0
                case 6: invert = (x * y % 2 + x * y % 3) % 2 == 0
                default: invert = ((x + y) % 2 + x * y % 3) % 2 == 0
                }
                if invert { modules[x, y].toggle() }
            }
        }
    }

    mutating func applyBestMask() {
        var best = 0
        var bestPenalty = Int.max
        for mask in 0..<8 {
            applyMask(mask)
            drawFormatBits(mask: mask)
            let penalty = QRPenalty.score(modules)
            if penalty < bestPenalty {
                best = mask
                bestPenalty = penalty
            }
            applyMask(mask)
        }
        applyMask(best)
        drawFormatBits(mask: best)
    }
}
