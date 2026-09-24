import Foundation

/// Décodeur Punycode minimal (RFC 3492).
enum Punycode {
    static func decode(_ input: String) -> String? {
        let base = 36, tMin = 1, tMax = 26, skew = 38, damp = 700
        var n = 128, i = 0, bias = 72
        var output: [Unicode.Scalar] = []
        var encoded = Substring(input)
        if let delimiter = input.lastIndex(of: "-") {
            output = input[..<delimiter].unicodeScalars.map { $0 }
            encoded = input[input.index(after: delimiter)...]
        }
        var characters = encoded.makeIterator()
        func digit(_ c: Character) -> Int? {
            guard let ascii = c.asciiValue else { return nil }
            switch ascii {
            case 48...57: return Int(ascii) - 22
            case 65...90: return Int(ascii) - 65
            case 97...122: return Int(ascii) - 97
            default: return nil
            }
        }
        func adapt(_ delta: Int, _ count: Int, _ first: Bool) -> Int {
            var delta = first ? delta / damp : delta / 2
            delta += delta / count
            var k = 0
            while delta > ((base - tMin) * tMax) / 2 {
                delta /= base - tMin
                k += base
            }
            return k + (base - tMin + 1) * delta / (delta + skew)
        }
        while let first = characters.next() {
            let oldI = i
            var w = 1
            var k = base
            var current: Character? = first
            while true {
                guard let c = current, let d = digit(c) else { return nil }
                i += d * w
                let t = k <= bias ? tMin : (k >= bias + tMax ? tMax : k - bias)
                if d < t { break }
                w *= base - t
                k += base
                current = characters.next()
            }
            bias = adapt(i - oldI, output.count + 1, oldI == 0)
            n += i / (output.count + 1)
            i %= output.count + 1
            guard let scalar = Unicode.Scalar(n) else { return nil }
            output.insert(scalar, at: i)
            i += 1
        }
        return String(String.UnicodeScalarView(output))
    }
}
