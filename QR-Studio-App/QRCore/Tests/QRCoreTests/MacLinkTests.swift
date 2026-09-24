import Foundation
import Testing
@testable import QRCore

@Suite("Appairage iPhone ↔ Mac")
struct MacLinkTests {
    @Test func pairingPayloadRoundTrip() throws {
        let pairing = try MacLinkPairing.generate(name: "Mac de Médéric")
        #expect(pairing.key.count == 32)
        let parsed = try #require(MacLinkPairing(qrPayload: pairing.qrPayload))
        #expect(parsed == pairing)
        #expect(pairing.qrPayload.hasPrefix("qrstudio-pair:"))
    }

    @Test func invalidPairingPayloadsAreRejected() {
        #expect(MacLinkPairing(qrPayload: "https://exemple.com") == nil)
        #expect(MacLinkPairing(qrPayload: "qrstudio-pair:1?id=x&name=a&key=abc") == nil)
    }

    @Test func pairingQRCodeIsReadable() async throws {
        let pairing = try MacLinkPairing.generate(name: "Mac de Médéric")
        let request = RenderRequest(payload: pairing.qrPayload, symbology: .qr)
        let drawing = try await CodeRenderer.shared.drawing(for: request)
        #expect(ReadabilityValidator.strictVerify(drawing, expecting: request) == .readable)
    }

    @Test func messageLine() throws {
        let message = MacLinkMessage(payload: "4006381333931", symbology: "ean13", date: Date(timeIntervalSince1970: 0))
        let line = try message.encodedLine()
        #expect(line.last == 0x0A)
        #expect(try MacLinkMessage.decode(line: line.dropLast()) == message)
    }
}
