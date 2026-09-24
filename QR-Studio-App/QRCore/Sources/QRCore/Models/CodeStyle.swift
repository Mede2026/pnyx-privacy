import Foundation
import SwiftData

/// Style visuel d'un code, ou preset personnel si `isUserPreset` est vrai.
///
/// Champs ajoutés à la spec (signalés) : gradientKind, eyeBallShape, eyeBallColorHex,
/// logoSymbolName, isBackgroundTransparent, frameEnabled, frameColorHex, caption, createdAt.
/// Ils sont nécessaires aux options de personnalisation décrites (dégradé radial, centre des yeux
/// séparé du contour, icône SF Symbols, fond transparent, cadre et légende).
@Model
public final class CodeStyle {
    public var id: UUID = UUID()
    public var foregroundHex: String = "#000000"
    public var backgroundHex: String = "#FFFFFF"
    public var gradientEndHex: String?
    public var gradientKind: String = "none"
    public var moduleShape: String = "square"
    /// Forme du contour des yeux.
    public var eyeShape: String = "square"
    /// Forme du centre des yeux.
    public var eyeBallShape: String = "square"
    /// Couleur du contour des yeux (nil = couleur des modules).
    public var eyeColorHex: String?
    /// Couleur du centre des yeux (nil = couleur du contour).
    public var eyeBallColorHex: String?
    /// Logo en PNG, sorti de la base par CloudKit grâce au stockage externe.
    @Attribute(.externalStorage) public var logoData: Data?
    public var logoSymbolName: String?
    public var logoScale: Double = 0.2
    public var errorCorrection: String = "M"
    public var quietZone: Int = 4
    public var isBackgroundTransparent: Bool = false
    public var frameEnabled: Bool = false
    public var frameColorHex: String?
    public var caption: String = ""
    public var isUserPreset: Bool = false
    public var presetName: String = ""
    public var createdAt: Date = Date()

    /// Inverse obligatoire pour CloudKit ; nil pour un preset.
    public var entry: CodeEntry?

    public init(config: StyleConfig = StyleConfig()) {
        self.id = UUID()
        self.createdAt = .now
        apply(config)
    }
}

public extension CodeStyle {
    /// Valeur immuable et Sendable, utilisable hors du fil principal par le moteur de rendu.
    var config: StyleConfig {
        var config = StyleConfig()
        config.foreground = RGBAColor(hex: foregroundHex) ?? .black
        config.background = isBackgroundTransparent ? nil : (RGBAColor(hex: backgroundHex) ?? .white)
        config.gradientKind = GradientKind(rawValue: gradientKind) ?? .none
        config.gradientEnd = gradientEndHex.flatMap(RGBAColor.init(hex:))
        config.moduleShape = ModuleShape(rawValue: moduleShape) ?? .square
        config.eyeFrameShape = EyeFrameShape(rawValue: eyeShape) ?? .square
        config.eyeBallShape = EyeBallShape(rawValue: eyeBallShape) ?? .square
        config.eyeFrameColor = eyeColorHex.flatMap(RGBAColor.init(hex:))
        config.eyeBallColor = eyeBallColorHex.flatMap(RGBAColor.init(hex:))
        config.logoPNG = logoData
        config.logoSymbolName = logoSymbolName
        config.logoScale = logoScale
        config.errorCorrection = ErrorCorrection(rawValue: errorCorrection) ?? .M
        config.quietZone = quietZone
        config.frameEnabled = frameEnabled
        config.frameColor = frameColorHex.flatMap(RGBAColor.init(hex:))
        config.caption = caption
        return config
    }

    func apply(_ config: StyleConfig) {
        foregroundHex = config.foreground.hex
        backgroundHex = (config.background ?? .white).hex
        isBackgroundTransparent = config.background == nil
        gradientKind = config.gradientKind.rawValue
        gradientEndHex = config.gradientEnd?.hex
        moduleShape = config.moduleShape.rawValue
        eyeShape = config.eyeFrameShape.rawValue
        eyeBallShape = config.eyeBallShape.rawValue
        eyeColorHex = config.eyeFrameColor?.hex
        eyeBallColorHex = config.eyeBallColor?.hex
        logoData = config.logoPNG
        logoSymbolName = config.logoSymbolName
        logoScale = config.logoScale
        errorCorrection = config.errorCorrection.rawValue
        quietZone = config.quietZone
        frameEnabled = config.frameEnabled
        frameColorHex = config.frameColor?.hex
        caption = config.caption
    }
}
