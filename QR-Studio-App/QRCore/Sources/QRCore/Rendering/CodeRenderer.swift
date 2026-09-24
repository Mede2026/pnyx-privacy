import CoreGraphics
import Foundation
import OSLog

/// Moteur de rendu. C'est un actor : le calcul ne passe jamais sur le fil principal,
/// seule l'affectation finale de l'image à la vue y revient.
public actor CodeRenderer {
    public static let shared = CodeRenderer()

    private struct MatrixKey: Hashable {
        var payload: String
        var correction: ErrorCorrection
    }

    /// Petit cache de matrices : changer de style ne recalcule pas le QR.
    private var matrices: [MatrixKey: BitMatrix] = [:]
    private var matrixOrder: [MatrixKey] = []

    public init() {}

    public func drawing(for request: RenderRequest) throws -> CodeDrawing {
        try CodeRenderer.validate(request)
        let style = request.style
        switch request.symbology {
        case .qr:
            let matrix = try qrMatrix(request.payload, correction: style.effectiveErrorCorrection)
            return QRStyledLayout.drawing(matrix: matrix, style: style)
        case .ean13:
            return LinearBarcodeDrawer.drawing(for: try LinearBarcodeEncoder.ean13(request.payload), style: style)
        case .ean8:
            return LinearBarcodeDrawer.drawing(for: try LinearBarcodeEncoder.ean8(request.payload), style: style)
        case .upcA:
            return LinearBarcodeDrawer.drawing(for: try LinearBarcodeEncoder.upcA(request.payload), style: style)
        case .code39:
            return LinearBarcodeDrawer.drawing(for: try LinearBarcodeEncoder.code39(request.payload), style: style)
        case .itf14, .i2of5:
            let symbol = try LinearBarcodeEncoder.interleaved2of5(request.payload, symbology: request.symbology)
            return LinearBarcodeDrawer.drawing(for: symbol, style: style)
        #if canImport(CoreImage)
        case .aztec:
            return GridBarcodeDrawer.drawing(for: try MatrixExtractor.aztecMatrix(for: request.payload),
                                             style: style, quietZone: 2)
        case .pdf417:
            return GridBarcodeDrawer.drawing(for: try MatrixExtractor.pdf417Matrix(for: request.payload),
                                             style: style, quietZone: 2)
        case .code128:
            let modules = try MatrixExtractor.code128Modules(for: request.payload)
            return LinearBarcodeDrawer.drawing(for: LinearBarcodeEncoder.code128(modules: modules,
                                                                                text: request.payload), style: style)
        #else
        case .code128:
            // watchOS : encodeur maison (une carte de fidélité doit garder son format d'origine).
            let modules = try Code128Encoder.modules(for: request.payload)
            return LinearBarcodeDrawer.drawing(for: LinearBarcodeEncoder.code128(modules: modules,
                                                                                text: request.payload), style: style)
        #endif
        default:
            throw RenderError.unsupportedOnPlatform(request.symbology)
        }
    }

    /// Image bitmap de la largeur demandée (en pixels).
    public func image(for request: RenderRequest, width: Int) throws -> CGImage {
        try drawing(for: request).makeImage(width: width)
    }

    /// Matrice brute d'un QR : Core Image quand il existe, l'encodeur maison sinon (watchOS).
    public func qrMatrix(_ payload: String, correction: ErrorCorrection) throws -> BitMatrix {
        let key = MatrixKey(payload: payload, correction: correction)
        if let cached = matrices[key] { return cached }
        #if canImport(CoreImage)
        let matrix = try MatrixExtractor.qrMatrix(for: payload, correction: correction)
        #else
        let matrix = try QREncoder.matrix(for: payload, correction: correction)
        #endif
        matrices[key] = matrix
        matrixOrder.append(key)
        if matrixOrder.count > 32 {
            matrices[matrixOrder.removeFirst()] = nil
        }
        return matrix
    }

    /// Vérifie la capacité avant de générer, pour un message d'erreur clair.
    public static func validate(_ request: RenderRequest) throws {
        let payload = request.payload
        guard !payload.isEmpty else { throw RenderError.invalidContent(L("Rien à encoder pour l’instant.")) }
        let bytes = payload.utf8.count
        switch request.symbology {
        case .qr:
            if bytes > request.style.effectiveErrorCorrection.qrByteCapacity {
                throw RenderError.capacityExceeded(symbology: .qr)
            }
        case .aztec:
            if bytes > 1914 { throw RenderError.capacityExceeded(symbology: .aztec) }
        case .pdf417:
            if bytes > 1850 { throw RenderError.capacityExceeded(symbology: .pdf417) }
        case .code128:
            if !payload.allSatisfy(\.isASCII) {
                throw RenderError.invalidContent(L("Le Code 128 n’accepte que les caractères ASCII."))
            }
            if payload.count > 80 { throw RenderError.capacityExceeded(symbology: .code128) }
        case .code39:
            if payload.count > 43 { throw RenderError.capacityExceeded(symbology: .code39) }
        default:
            break
        }
    }
}
