import CoreGraphics
import Foundation
import Testing
@testable import QRCore

/// Générer puis relire avec Vision doit redonner le contenu d'origine.
/// C'est le test le plus important : il attrape les régressions de style qui rendent un code illisible.
@Suite("Aller-retour génération → lecture Vision")
struct RoundTripTests {
    private let payloads = [
        "Bonjour",
        "https://exemple.com/un/chemin?avec=parametres&et=accents-éàü",
        "WIFI:T:WPA;S:MonReseau;P:motdepasse;H:false;;",
        String(repeating: "QR Studio 🙂 ", count: 40)
    ]

    private func assertReadable(_ request: RenderRequest, sourceLocation: SourceLocation = #_sourceLocation) async throws {
        let drawing = try await CodeRenderer.shared.drawing(for: request)
        let result = ReadabilityValidator.strictVerify(drawing, expecting: request)
        #expect(result == .readable, "\(request.symbology.displayName) illisible : \(request.payload.prefix(40))",
                sourceLocation: sourceLocation)
    }

    @Test func plainQRCodes() async throws {
        for payload in payloads {
            for level in ErrorCorrection.allCases {
                var style = StyleConfig()
                style.errorCorrection = level
                try await assertReadable(RenderRequest(payload: payload, symbology: .qr, style: style))
            }
        }
    }

    @Test(arguments: StylePresets.all)
    func everyFactoryPresetStaysReadable(preset: StylePreset) async throws {
        for payload in payloads {
            try await assertReadable(RenderRequest(payload: payload, symbology: .qr, style: preset.config))
        }
    }

    @Test(arguments: ModuleShape.allCases)
    func everyModuleShapeWithEveryEye(shape: ModuleShape) async throws {
        for frame in EyeFrameShape.allCases {
            for ball in EyeBallShape.allCases {
                var style = StyleConfig()
                style.moduleShape = shape
                style.eyeFrameShape = frame
                style.eyeBallShape = ball
                try await assertReadable(RenderRequest(payload: payloads[1], symbology: .qr, style: style))
            }
        }
    }

    @Test func logoAtMaximumSize() async throws {
        var style = StyleConfig()
        style.logoPNG = try Self.logoPNG()
        style.logoScale = 0.25
        style.errorCorrection = .L // doit être forcé à H
        for payload in payloads.prefix(3) {
            try await assertReadable(RenderRequest(payload: payload, symbology: .qr, style: style))
        }
    }

    @Test func frameAndCaption() async throws {
        var style = StyleConfig()
        style.frameEnabled = true
        style.caption = "Scannez-moi"
        try await assertReadable(RenderRequest(payload: payloads[1], symbology: .qr, style: style))
    }

    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    /// Le simulateur n'a pas de Vision complète : seul le QR y est lu (repli CIDetector).
    /// Ce test tourne avec `swift test` sur le Mac et sur appareil.
    @Test(.enabled(if: !Self.isSimulator), arguments: [
        (Symbology.aztec, "AZTEC: https://exemple.com/a?b=1"),
        (.pdf417, "PDF417 : https://exemple.com"),
        (.code128, "QR-STUDIO-128"),
        (.ean13, "4006381333931"),
        (.ean8, "96385074"),
        (.upcA, "036000291452"),
        (.code39, "QR STUDIO-39"),
        (.itf14, "09506000134376"),
        (.i2of5, "12345678")
    ])
    func otherSymbologies(symbology: Symbology, payload: String) async throws {
        try await assertReadable(RenderRequest(payload: payload, symbology: symbology))
    }

    /// Aztec et PDF417 n'ont pas d'indicateur d'encodage : les lecteurs supposent ISO-8859-1.
    /// Le validateur doit donc signaler un contenu accentué comme illisible, plutôt que de le laisser passer.
    @Test func nonASCIIAztecIsFlagged() async throws {
        let request = RenderRequest(payload: "Aztec éàü", symbology: .aztec)
        let drawing = try await CodeRenderer.shared.drawing(for: request)
        #expect(ReadabilityValidator.strictVerify(drawing, expecting: request) != .readable)
    }

    /// L'encodeur Swift pur (utilisé sur la montre) doit produire des codes lisibles.
    @Test(arguments: ErrorCorrection.allCases)
    func pureSwiftEncoder(level: ErrorCorrection) throws {
        let lengths = [1, 17, 60, 150, 400, 900]
        for length in lengths where length <= level.qrByteCapacity {
            let payload = String((0..<length).map { index in
                Array("abcdefghijklmnopqrstuvwxyz0123456789-é")[index % 38]
            })
            let matrix = try QREncoder.matrix(for: payload, correction: level)
            var style = StyleConfig()
            style.errorCorrection = level
            let drawing = QRStyledLayout.drawing(matrix: matrix, style: style)
            let request = RenderRequest(payload: payload, symbology: .qr, style: style)
            #expect(ReadabilityValidator.strictVerify(drawing, expecting: request) == .readable,
                    "Encodeur maison illisible, niveau \(level.rawValue), \(length) caractères")
        }
    }

    @Test func pureEncoderMatchesCoreImageVersion() async throws {
        let payload = "https://exemple.com"
        let pure = try QREncoder.matrix(for: payload, correction: .M)
        let coreImage = try await CodeRenderer.shared.qrMatrix(payload, correction: .M)
        #expect(pure.width == coreImage.width)
    }

    @Test func vectorFormats() async throws {
        var style = StyleConfig()
        style.gradientKind = .radial
        style.gradientEnd = RGBAColor(hex: "#1A237E")
        style.logoPNG = try Self.logoPNG()
        let drawing = try await CodeRenderer.shared.drawing(for: RenderRequest(payload: "SVG", symbology: .qr, style: style))
        let svg = drawing.svgString()
        #expect(svg.hasPrefix("<?xml"))
        #expect(svg.contains("radialGradient"))
        #expect(svg.contains("data:image/png;base64,"))
        let pdf = try drawing.pdfData()
        #expect(pdf.starts(with: Data("%PDF".utf8)))
        let png = try drawing.pngData(width: 2048)
        #expect(png.count > 1000)
    }

    @Test func capacityIsEnforced() async {
        var style = StyleConfig()
        style.errorCorrection = .H
        let tooLong = String(repeating: "x", count: 1300)
        await #expect(throws: RenderError.capacityExceeded(symbology: .qr)) {
            try await CodeRenderer.shared.drawing(for: RenderRequest(payload: tooLong, symbology: .qr, style: style))
        }
    }

    static func logoPNG() throws -> Data {
        guard let context = CGContext(data: nil, width: 64, height: 64, bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw RenderError.contextCreationFailed
        }
        context.setFillColor(CGColor(red: 0.9, green: 0.1, blue: 0.2, alpha: 1))
        context.fillEllipse(in: CGRect(x: 4, y: 4, width: 56, height: 56))
        guard let image = context.makeImage() else { throw RenderError.contextCreationFailed }
        return try CodeDrawing.encode(image, type: .png)
    }
}

/// L'encodeur Code 128 maison (utilisé sur la montre) doit être relu par Vision.
@Suite("Code 128 en Swift pur")
struct Code128EncoderTests {
    @Test func everyPatternHasElevenModules() {
        for (value, pattern) in Code128Encoder.patterns.enumerated() {
            let total = pattern.compactMap(\.wholeNumberValue).reduce(0, +)
            #expect(total == (value == 106 ? 13 : 11), "symbole \(value)")
        }
    }

    @Test(.enabled(if: !RoundTripTests.isSimulator),
          arguments: ["QR-STUDIO-128", "1234567890", "A1234567B", "carte 00123456789", "x", "9", "Prix: 12,50 $"])
    func pureSwiftCode128IsReadable(payload: String) async throws {
        let modules = try Code128Encoder.modules(for: payload)
        let drawing = LinearBarcodeDrawer.drawing(for: LinearBarcodeEncoder.code128(modules: modules, text: payload),
                                                  style: StyleConfig())
        let codes = try ImageBarcodeDecoder.decode(imageData: try drawing.pngData(width: 1200))
        #expect(codes.contains { $0.payload == payload && $0.symbology == .code128 })
    }
}
