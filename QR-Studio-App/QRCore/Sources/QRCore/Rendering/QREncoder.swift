import Foundation

/// Encodeur QR en Swift pur (mode octet, versions 1 à 40).
///
/// Core Image n'existe pas sur watchOS : la montre calcule ses codes avec cet encodeur.
/// Sur iPhone, iPad et Mac, c'est CIFilter.qrCodeGenerator qui est utilisé.
public enum QREncoder {
    public static func matrix(for payload: String, correction: ErrorCorrection) throws -> BitMatrix {
        let bytes = [UInt8](payload.utf8)
        guard let version = (1...40).first(where: { fits(bytes.count, version: $0, level: correction) }) else {
            throw RenderError.capacityExceeded(symbology: .qr)
        }
        var builder = Builder(version: version, level: correction)
        builder.drawFunctionPatterns()
        builder.drawCodewords(interleaved(dataCodewords(bytes, version: version, level: correction),
                                          version: version, level: correction))
        builder.applyBestMask()
        return builder.modules
    }

    private static func characterCountBits(version: Int) -> Int {
        version <= 9 ? 8 : 16
    }

    private static func fits(_ count: Int, version: Int, level: ErrorCorrection) -> Bool {
        let bits = 4 + characterCountBits(version: version) + count * 8
        return bits <= QRTables.dataCodewords(version: version, level: level) * 8
            && count < (1 << characterCountBits(version: version))
    }

    /// Segment en mode octet (0100), terminateur, puis octets de bourrage 0xEC / 0x11.
    private static func dataCodewords(_ bytes: [UInt8], version: Int, level: ErrorCorrection) -> [UInt8] {
        var bits: [Bool] = []
        func append(_ value: Int, _ length: Int) {
            for i in stride(from: length - 1, through: 0, by: -1) { bits.append((value >> i) & 1 == 1) }
        }
        append(0b0100, 4)
        append(bytes.count, characterCountBits(version: version))
        for byte in bytes { append(Int(byte), 8) }

        let capacity = QRTables.dataCodewords(version: version, level: level) * 8
        append(0, min(4, capacity - bits.count))
        append(0, (8 - bits.count % 8) % 8)
        var pad = 0xEC
        while bits.count < capacity {
            append(pad, 8)
            pad ^= 0xEC ^ 0x11
        }
        return stride(from: 0, to: bits.count, by: 8).map { start in
            bits[start..<(start + 8)].reduce(UInt8(0)) { ($0 << 1) | ($1 ? 1 : 0) }
        }
    }

    /// Découpe en blocs, ajoute la correction Reed-Solomon et entrelace.
    private static func interleaved(_ data: [UInt8], version: Int, level: ErrorCorrection) -> [UInt8] {
        let i = QRTables.levelIndex(level)
        let blockCount = QRTables.errorCorrectionBlocks[i][version]
        let eccLength = QRTables.eccCodewordsPerBlock[i][version]
        let rawCodewords = QRTables.rawDataModules(version: version) / 8
        let shortBlocks = blockCount - rawCodewords % blockCount
        let shortLength = rawCodewords / blockCount
        let divisor = ReedSolomon.divisor(degree: eccLength)

        var blocks: [[UInt8]] = []
        var offset = 0
        for index in 0..<blockCount {
            let length = shortLength - eccLength + (index < shortBlocks ? 0 : 1)
            var block = Array(data[offset..<(offset + length)])
            offset += length
            let ecc = ReedSolomon.remainder(block, divisor: divisor)
            if index < shortBlocks { block.append(0) }
            blocks.append(block + ecc)
        }

        var result: [UInt8] = []
        for position in 0..<blocks[0].count {
            for (index, block) in blocks.enumerated()
            where position != shortLength - eccLength || index >= shortBlocks {
                result.append(block[position])
            }
        }
        return result
    }
}
