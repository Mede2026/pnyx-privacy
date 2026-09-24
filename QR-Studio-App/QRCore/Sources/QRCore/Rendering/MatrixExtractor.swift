#if canImport(CoreImage)
import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

/// Génère un code avec Core Image à l'échelle 1 (un pixel par module),
/// puis lit les pixels pour obtenir la matrice de modules.
enum MatrixExtractor {
    private static let context = CIContext(options: [.useSoftwareRenderer: false])

    static func qrMatrix(for payload: String, correction: ErrorCorrection) throws -> BitMatrix {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = correction.rawValue
        guard let image = filter.outputImage else { throw RenderError.capacityExceeded(symbology: .qr) }
        var matrix = try read(image).trimmed()
        // Sécurité : les motifs de repérage doivent être en haut à gauche, en haut à droite
        // et en bas à gauche. S'ils apparaissent en bas à droite, l'image a été lue à l'envers.
        if !matrix.hasFinderPattern(atX: matrix.width - 7, y: 0),
           matrix.hasFinderPattern(atX: matrix.width - 7, y: matrix.height - 7) {
            matrix = matrix.flippedVertically()
        }
        return matrix
    }

    static func aztecMatrix(for payload: String) throws -> BitMatrix {
        let filter = CIFilter.aztecCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = 23
        guard let image = filter.outputImage else { throw RenderError.capacityExceeded(symbology: .aztec) }
        return try read(image).trimmed()
    }

    static func pdf417Matrix(for payload: String) throws -> BitMatrix {
        let filter = CIFilter.pdf417BarcodeGenerator()
        filter.message = Data(payload.utf8)
        guard let image = filter.outputImage else { throw RenderError.capacityExceeded(symbology: .pdf417) }
        return try read(image).trimmed()
    }

    /// Code 128 : ASCII seulement. Renvoie la suite de modules d'une ligne.
    static func code128Modules(for payload: String) throws -> [Bool] {
        guard let data = payload.data(using: .ascii), !payload.isEmpty else {
            throw RenderError.invalidContent(L("Le Code 128 n’accepte que les caractères ASCII."))
        }
        let filter = CIFilter.code128BarcodeGenerator()
        filter.message = data
        filter.quietSpace = 0
        filter.barcodeHeight = 4
        guard let image = filter.outputImage else { throw RenderError.capacityExceeded(symbology: .code128) }
        let matrix = try read(image)
        let row = matrix.height / 2
        return (0..<matrix.width).map { matrix[$0, row] }
    }

    private static func read(_ image: CIImage) throws -> BitMatrix {
        let extent = image.extent.integral
        let width = Int(extent.width)
        let height = Int(extent.height)
        guard width > 0, height > 0,
              let cgImage = context.createCGImage(image, from: extent),
              let bitmap = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue
              ) else {
            throw RenderError.contextCreationFailed
        }
        bitmap.interpolationQuality = .none
        bitmap.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = bitmap.data else { throw RenderError.contextCreationFailed }
        // Dans un contexte bitmap, la première ligne en mémoire est le haut de l'image.
        let pixels = data.bindMemory(to: UInt8.self, capacity: width * height)
        var bits = [Bool](repeating: false, count: width * height)
        for index in 0..<(width * height) {
            bits[index] = pixels[index] < 128
        }
        return BitMatrix(width: width, height: height, bits: bits)
    }
}
#endif
