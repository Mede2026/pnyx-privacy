import CoreGraphics
import Foundation

public enum ReadabilityValidator {
    public static let minimumContrast = 4.0

    public static func checkColors(_ style: StyleConfig) -> ColorCheck {
        let background = style.measuredBackground
        let colors = style.foregroundColors.map { $0.composited(over: background) }
        let ratios = colors.map { RGBAColor.contrastRatio($0, background) }
        let worst = ratios.min() ?? 21
        let inverted = colors.contains { $0.relativeLuminance > background.relativeLuminance }
        return ColorCheck(contrastRatio: worst, isContrastTooLow: worst < minimumContrast, isInverted: inverted)
    }

    #if canImport(Vision) && !os(watchOS)
    /// Garde-fou n° 6 : relit l'image générée avec Vision et compare au contenu attendu.
    /// C'est la vérification la plus importante du module de personnalisation.
    public static func verify(_ drawing: CodeDrawing, expecting request: RenderRequest) -> Readability {
        let result = strictVerify(drawing, expecting: request)
        #if targetEnvironment(simulator)
        // Dans le simulateur iOS, Vision rate des codes pourtant valides : on ne bloque pas,
        // mais on le dit. Sur un appareil réel, la vérification reste stricte.
        if case .unreadable = result {
            return .unverified(L("Relecture non vérifiable dans le simulateur. Elle est faite sur un appareil réel."))
        }
        #endif
        return result
    }

    static func strictVerify(_ drawing: CodeDrawing, expecting request: RenderRequest) -> Readability {
        var opaque = drawing
        if opaque.background == nil { opaque.background = .white }
        // Les codes linéaires ont besoin de plus de pixels par module.
        let width = request.symbology.isTwoDimensional ? 720 : 1200
        do {
            let image = try opaque.makeImage(width: width)
            let decoded = try ImageBarcodeDecoder.decode(image)
            if decoded.contains(where: { matches($0.payload, request.payload, symbology: request.symbology) }) {
                return .readable
            }
            return .unreadable(L("Le code n’a pas pu être relu. Augmentez le contraste ou la zone silencieuse, ou réduisez le logo."))
        } catch {
            return .unreadable(error.localizedDescription)
        }
    }

    /// Relecture complète : rendu puis vérification, hors du fil principal.
    public static func verify(_ request: RenderRequest) async -> Readability {
        do {
            let drawing = try await CodeRenderer.shared.drawing(for: request)
            return verify(drawing, expecting: request)
        } catch {
            return .unreadable(error.localizedDescription)
        }
    }
    #endif

    /// Compare en tenant compte des normalisations des lecteurs (UPC-A lu en EAN-13, Code 39 en majuscules).
    static func matches(_ decoded: String, _ expected: String, symbology: Symbology) -> Bool {
        if decoded == expected { return true }
        switch symbology {
        case .ean13, .ean8, .upcA, .itf14:
            return GTIN.normalized(decoded) == GTIN.normalized(expected)
        case .code39:
            return decoded.uppercased() == expected.uppercased()
        default:
            return false
        }
    }
}
