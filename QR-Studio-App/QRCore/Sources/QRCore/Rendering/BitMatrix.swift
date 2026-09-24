import Foundation

/// Grille de modules : vrai = module noir.
public struct BitMatrix: Sendable, Hashable {
    public let width: Int
    public let height: Int
    private var bits: [Bool]

    public init(width: Int, height: Int, bits: [Bool]) {
        precondition(bits.count == width * height, "BitMatrix : taille incohérente")
        self.width = width
        self.height = height
        self.bits = bits
    }

    public init(width: Int, height: Int) {
        self.init(width: width, height: height, bits: Array(repeating: false, count: width * height))
    }

    /// Lecture tolérante : hors de la grille, un module est blanc.
    public subscript(x: Int, y: Int) -> Bool {
        get {
            guard x >= 0, y >= 0, x < width, y < height else { return false }
            return bits[y * width + x]
        }
        set {
            guard x >= 0, y >= 0, x < width, y < height else { return }
            bits[y * width + x] = newValue
        }
    }

    /// Représentation [[Bool]] demandée par la spec (ligne par ligne).
    public var rows: [[Bool]] {
        (0..<height).map { y in Array(bits[(y * width)..<((y + 1) * width)]) }
    }

    public var darkCount: Int { bits.count { $0 } }

    /// Retire la marge blanche autour des modules noirs.
    public func trimmed() -> BitMatrix {
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width where self[x, y] {
                minX = min(minX, x)
                maxX = max(maxX, x)
                minY = min(minY, y)
                maxY = max(maxY, y)
            }
        }
        guard maxX >= minX, maxY >= minY else { return self }
        let w = maxX - minX + 1
        let h = maxY - minY + 1
        var result = BitMatrix(width: w, height: h)
        for y in 0..<h {
            for x in 0..<w {
                result[x, y] = self[x + minX, y + minY]
            }
        }
        return result
    }

    public func flippedVertically() -> BitMatrix {
        var result = BitMatrix(width: width, height: height)
        for y in 0..<height {
            for x in 0..<width {
                result[x, height - 1 - y] = self[x, y]
            }
        }
        return result
    }

    /// Vrai si un motif de repérage QR (7 × 7) commence à (x, y).
    func hasFinderPattern(atX x0: Int, y y0: Int) -> Bool {
        for y in 0..<7 {
            for x in 0..<7 {
                let ring = x == 0 || y == 0 || x == 6 || y == 6
                let core = (2...4).contains(x) && (2...4).contains(y)
                if self[x0 + x, y0 + y] != (ring || core) { return false }
            }
        }
        return true
    }
}
