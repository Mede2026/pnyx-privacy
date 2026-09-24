import CryptoKit
import Foundation

/// Style de rendu, sous forme de valeur. C'est ce que reçoit le moteur de rendu.
public struct StyleConfig: Hashable, Sendable, Codable {
    public var foreground: RGBAColor = .black
    /// nil = fond transparent.
    public var background: RGBAColor? = .white
    public var gradientKind: GradientKind = .none
    public var gradientEnd: RGBAColor?
    public var moduleShape: ModuleShape = .square
    public var eyeFrameShape: EyeFrameShape = .square
    public var eyeBallShape: EyeBallShape = .square
    public var eyeFrameColor: RGBAColor?
    public var eyeBallColor: RGBAColor?
    public var logoPNG: Data?
    public var logoSymbolName: String?
    public var logoScale: Double = 0.2
    public var errorCorrection: ErrorCorrection = .M
    public var quietZone: Int = 4
    public var frameEnabled: Bool = false
    public var frameColor: RGBAColor?
    public var caption: String = ""

    public init() {}

    public static let logoScaleRange: ClosedRange<Double> = 0.10...0.25
    public static let quietZoneRange: ClosedRange<Int> = 1...8
    public static let recommendedQuietZone = 4

    public var hasLogo: Bool { logoPNG != nil }

    /// Garde-fou n° 1 : un logo impose le niveau de correction H.
    public var effectiveErrorCorrection: ErrorCorrection {
        hasLogo ? .H : errorCorrection
    }

    /// Garde-fou n° 2 : jamais plus de 25 % de la largeur.
    public var effectiveLogoScale: Double {
        logoScale.clamped(to: Self.logoScaleRange)
    }

    public var effectiveQuietZone: Int {
        quietZone.clamped(to: Self.quietZoneRange)
    }

    /// Couleur de fond utilisée pour les mesures de contraste (blanc si transparent).
    public var measuredBackground: RGBAColor {
        (background ?? .white)
    }

    /// Toutes les couleurs dessinées au premier plan, pour la vérification du contraste.
    public var foregroundColors: [RGBAColor] {
        var colors = [foreground]
        if gradientKind != .none, let gradientEnd { colors.append(gradientEnd) }
        if let eyeFrameColor { colors.append(eyeFrameColor) }
        if let eyeBallColor { colors.append(eyeBallColor) }
        return colors
    }

    /// Empreinte stable du style, utilisée comme clé du cache de vignettes.
    public var fingerprint: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data: Data
        do {
            data = try encoder.encode(self)
        } catch {
            // Encodage de types simples : ne peut pas échouer en pratique ; repli sur la description.
            data = Data(String(describing: self).utf8)
        }
        let digest = SHA256.hash(data: data)
        return digest.prefix(8).map { String(format: "%02x", $0) }.joined()
    }
}
