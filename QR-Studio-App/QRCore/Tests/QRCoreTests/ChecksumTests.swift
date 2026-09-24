import Testing
@testable import QRCore

@Suite("Sommes de contrôle GS1")
struct ChecksumTests {
    @Test(arguments: ["4006381333931", "5901234123457", "9780201379624", "0012345678905"])
    func validEAN13(code: String) {
        #expect(GTIN.isValid(code))
    }

    @Test(arguments: ["036000291452", "012345678905", "042100005264"])
    func validUPCA(code: String) {
        #expect(GTIN.isValid(code))
    }

    @Test func validEAN8AndGTIN14() {
        #expect(GTIN.isValid("96385074"))
        #expect(GTIN.isValid("09506000134376"))
    }

    @Test func invalidCodesAreRejected() {
        #expect(!GTIN.isValid("4006381333932"))
        #expect(!GTIN.isValid("036000291453"))
        #expect(!GTIN.isValid("abcdefghijklm"))
        #expect(!GTIN.isValid("12345"))
    }

    @Test func checkDigitComputation() {
        #expect(GTIN.checkDigit(for: [4, 0, 0, 6, 3, 8, 1, 3, 3, 3, 9, 3]) == 1)
        #expect(GTIN.checkDigit(for: [0, 3, 6, 0, 0, 0, 2, 9, 1, 4, 5]) == 2)
        #expect(GTIN.expectedCheckDigit(for: "4006381333930") == 1)
    }

    @Test func normalization() {
        #expect(GTIN.normalized("4006381333931") == "04006381333931")
        #expect(GTIN.normalized("96385074") == "00000096385074")
        #expect(GTIN.formatted("4006381333931") == "4 006381 333931")
    }

    @Test func registrationCountry() {
        #expect(GTIN.registrationCountry(for: "0012345678905") != nil)
        #expect(GTIN.registrationCountry(for: "3017620422003") != nil) // France
        #expect(GTIN.registrationCountry(for: "9780201379624") == nil) // ISBN, hors table
    }
}
