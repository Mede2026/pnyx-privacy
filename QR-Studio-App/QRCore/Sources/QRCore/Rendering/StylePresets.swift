import Foundation

public enum StylePresets {
    public static var all: [StylePreset] {
        [
            preset("classic", L("Classique")) { _ in },
            preset("soft", L("Doux")) {
                $0.moduleShape = .rounded
                $0.eyeFrameShape = .rounded
                $0.eyeBallShape = .rounded
            },
            preset("dots", L("Points")) {
                $0.moduleShape = .circle
                $0.eyeFrameShape = .circle
                $0.eyeBallShape = .circle
            },
            preset("liquid", L("Liquide")) {
                $0.moduleShape = .connected
                $0.eyeFrameShape = .rounded
                $0.eyeBallShape = .rounded
                $0.foreground = hex("#1C1C1E")
            },
            preset("ocean", L("Océan")) {
                $0.moduleShape = .rounded
                $0.gradientKind = .linear
                $0.foreground = hex("#0A3D91")
                $0.gradientEnd = hex("#0B7285")
                $0.eyeFrameShape = .rounded
                $0.eyeBallShape = .circle
                $0.eyeFrameColor = hex("#062A66")
            },
            preset("sunset", L("Coucher de soleil")) {
                $0.moduleShape = .rounded
                $0.gradientKind = .radial
                $0.foreground = hex("#6D0F2E")
                $0.gradientEnd = hex("#9A2F0A")
                $0.eyeFrameShape = .rounded
                $0.eyeBallShape = .rounded
            },
            preset("forest", L("Forêt")) {
                $0.moduleShape = .diamond
                $0.foreground = hex("#1E4D2B")
                $0.eyeFrameShape = .square
                $0.eyeBallShape = .diamond
                $0.background = hex("#F4F1E8")
            },
            preset("grape", L("Raisin")) {
                $0.moduleShape = .connected
                $0.foreground = hex("#4B1D7A")
                $0.eyeFrameShape = .circle
                $0.eyeBallShape = .circle
                $0.eyeBallColor = hex("#9C2F6B")
            },
            preset("scanMe", L("Scannez-moi")) {
                $0.moduleShape = .rounded
                $0.eyeFrameShape = .rounded
                $0.eyeBallShape = .rounded
                $0.frameEnabled = true
                $0.caption = L("SCANNEZ-MOI")
            },
            preset("mono", L("Plan")) {
                $0.moduleShape = .square
                $0.foreground = hex("#0B2545")
                $0.background = hex("#EEF4FB")
                $0.eyeFrameShape = .square
                $0.eyeBallShape = .square
                $0.quietZone = 3
            }
        ]
    }

    private static func preset(_ id: String, _ name: String, _ configure: (inout StyleConfig) -> Void) -> StylePreset {
        var config = StyleConfig()
        configure(&config)
        return StylePreset(id: id, name: name, config: config)
    }

    private static func hex(_ value: String) -> RGBAColor {
        RGBAColor(hex: value) ?? .black
    }
}
