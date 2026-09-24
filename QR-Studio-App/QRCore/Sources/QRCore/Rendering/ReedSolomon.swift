import Foundation

/// Reed-Solomon sur GF(2⁸), polynôme 0x11D.
enum ReedSolomon {
    static func multiply(_ x: UInt8, _ y: UInt8) -> UInt8 {
        var z: Int = 0
        for i in stride(from: 7, through: 0, by: -1) {
            z = (z << 1) ^ ((z >> 7) * 0x11D)
            z ^= Int((y >> UInt8(i)) & 1) * Int(x)
        }
        return UInt8(z & 0xFF)
    }

    static func divisor(degree: Int) -> [UInt8] {
        var result = [UInt8](repeating: 0, count: degree)
        result[degree - 1] = 1
        var root: UInt8 = 1
        for _ in 0..<degree {
            for j in 0..<degree {
                result[j] = multiply(result[j], root)
                if j + 1 < degree { result[j] ^= result[j + 1] }
            }
            root = multiply(root, 0x02)
        }
        return result
    }

    static func remainder(_ data: [UInt8], divisor: [UInt8]) -> [UInt8] {
        var result = [UInt8](repeating: 0, count: divisor.count)
        for byte in data {
            let factor = byte ^ result.removeFirst()
            result.append(0)
            for i in 0..<result.count {
                result[i] ^= multiply(divisor[i], factor)
            }
        }
        return result
    }
}
