import Foundation
import Testing
@testable import QRCore

@Suite("Garde-fous de lisibilité")
struct ReadabilityTests {
    private func style(_ foreground: String, on background: String) -> StyleConfig {
        var style = StyleConfig()
        style.foreground = RGBAColor(hex: foreground) ?? .black
        style.background = RGBAColor(hex: background)
        return style
    }

    @Test func blackOnWhiteIsFine() {
        let check = ReadabilityValidator.checkColors(style("#000000", on: "#FFFFFF"))
        #expect(!check.isContrastTooLow)
        #expect(!check.isInverted)
        #expect(abs(check.contrastRatio - 21) < 0.01)
    }

    @Test(arguments: [("#AAAAAA", "#FFFFFF"), ("#FFFF00", "#FFFFFF"), ("#777777", "#555555"), ("#0000FF", "#000080")])
    func lowContrastIsRejected(foreground: String, background: String) {
        #expect(ReadabilityValidator.checkColors(style(foreground, on: background)).isContrastTooLow)
    }

    @Test func lightOnDarkIsFlagged() {
        let check = ReadabilityValidator.checkColors(style("#FFFFFF", on: "#000000"))
        #expect(!check.isContrastTooLow)
        #expect(check.isInverted)
    }

    @Test func gradientEndAndEyeColorsAreChecked() {
        var gradient = style("#000000", on: "#FFFFFF")
        gradient.gradientKind = .linear
        gradient.gradientEnd = RGBAColor(hex: "#DDDDDD")
        #expect(ReadabilityValidator.checkColors(gradient).isContrastTooLow)

        var eyes = style("#000000", on: "#FFFFFF")
        eyes.eyeBallColor = RGBAColor(hex: "#EEEEEE")
        #expect(ReadabilityValidator.checkColors(eyes).isContrastTooLow)
    }

    @Test func translucentForegroundIsMeasuredAsSeen() {
        var translucent = style("#000000", on: "#FFFFFF")
        translucent.foreground = RGBAColor(red: 0, green: 0, blue: 0, alpha: 0.2)
        #expect(ReadabilityValidator.checkColors(translucent).isContrastTooLow)
    }

    @Test func logoForcesLevelHAndCapsScale() {
        var style = StyleConfig()
        style.errorCorrection = .L
        style.logoPNG = Data([0x89])
        style.logoScale = 0.6
        #expect(style.effectiveErrorCorrection == .H)
        #expect(style.effectiveLogoScale == 0.25)
    }
}
