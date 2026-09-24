import Foundation
import Testing
@testable import QRCore

@Suite("ScannedContentParser : chaque chaîne connue est bien classée")
struct ParserTests {
    @Test(arguments: [
        ("WIFI:T:WPA;S:MonReseau;P:motdepasse;H:false;;", ContentType.wifi),
        ("WIFI:T:WPA2-EAP;S:Bureau;U:jdoe;P:x;E:PEAP;;", .wifiEnterprise),
        ("BEGIN:VCARD\r\nVERSION:3.0\r\nFN:Marie\r\nEND:VCARD", .contact),
        ("MECARD:N:Doe,John;TEL:5145550123;;", .contact),
        ("geo:45.5906,-73.4503", .location),
        ("http://maps.apple.com/?ll=45.5906,-73.4503", .location),
        ("https://www.google.com/maps/place/X/@45.5,-73.5,15z", .location),
        ("mailto:a@b.com?subject=Salut", .email),
        ("MATMSG:TO:a@b.com;SUB:Hi;BODY:Yo;;", .email),
        ("SMSTO:+15145550123:Mon message", .sms),
        ("sms:+15145550123?body=Salut", .sms),
        ("tel:+15145550123", .phone),
        ("BEGIN:VEVENT\r\nSUMMARY:Test\r\nDTSTART:20260919T120000Z\r\nEND:VEVENT", .event),
        ("BEGIN:VCALENDAR\nBEGIN:VEVENT\nSUMMARY:X\nEND:VEVENT\nEND:VCALENDAR", .event),
        ("https://exemple.com/page", .url),
        ("https://marque.com/01/09506000134376", .product),
        ("https://id.gs1.org/01/09506000134376/10/ABC", .product),
        ("bitcoin:bc1qxyz?amount=0.01", .crypto),
        ("4006381333931", .product),
        ("036000291452", .product),
        ("Bonjour tout le monde", .text),
        ("12345", .text)
    ])
    func classification(input: String, expected: ContentType) {
        #expect(ScannedContentParser.parse(input).contentType == expected)
    }

    @Test func wifiFieldsWithEscapes() throws {
        let parsed = ScannedContentParser.parse(#"WIFI:S:Café\;Wi\:Fi;T:WPA;P:a\\b\,c;H:true;;"#)
        guard case .wifi(let network) = parsed else {
            Issue.record("Wi-Fi attendu")
            return
        }
        #expect(network.ssid == "Café;Wi:Fi")
        #expect(network.password == #"a\b,c"#)
        #expect(network.hidden)
        #expect(network.security == "WPA")
    }

    @Test func vCardFields() {
        let card = """
        BEGIN:VCARD
        VERSION:3.0
        N:Tremblay;Marie;;;
        FN:Marie Tremblay
        ORG:Studio\\, Inc.
        TEL;TYPE=CELL:+15145550123
        item1.EMAIL;TYPE=INTERNET:marie@exemple.ca
        ADR;TYPE=WORK:;;123 rue Principale;Montréal;QC;H2X 1Y4;Canada
        NOTE:Ligne 1\\nLigne 2
        END:VCARD
        """
        guard case .contact(let contact) = ScannedContentParser.parse(card) else {
            Issue.record("Contact attendu")
            return
        }
        #expect(contact.displayName == "Marie Tremblay")
        #expect(contact.firstName == "Marie")
        #expect(contact.organization == "Studio, Inc.")
        #expect(contact.phones == ["+15145550123"])
        #expect(contact.emails == ["marie@exemple.ca"])
        #expect(contact.addresses == ["123 rue Principale, Montréal, QC, H2X 1Y4, Canada"])
        #expect(contact.note == "Ligne 1\nLigne 2")
    }

    @Test func eventDates() {
        let text = "BEGIN:VEVENT\nSUMMARY:Réunion\nDTSTART:20260919T120000Z\nDTEND:20260919T133000Z\nEND:VEVENT"
        guard case .event(let event) = ScannedContentParser.parse(text) else {
            Issue.record("Événement attendu")
            return
        }
        #expect(event.title == "Réunion")
        #expect(event.start == Date(timeIntervalSince1970: 1_789_819_200))
        #expect(event.duration == 5400)
    }

    @Test func digitalLinkExtractsGTIN() {
        guard case .product(let product) = ScannedContentParser.parse("https://marque.com/01/09506000134376?x=1") else {
            Issue.record("Produit attendu")
            return
        }
        #expect(product.gtin == "09506000134376")
        #expect(product.isDigitalLink)
        #expect(product.searchCode == "9506000134376")
    }

    @Test func upcEIsExpanded() {
        guard case .product(let product) = ScannedContentParser.parse("04252614", symbology: .upcE) else {
            Issue.record("Produit attendu")
            return
        }
        #expect(product.code == "042100005264")
    }

    @Test func locationCoordinates() {
        guard case .location(let point) = ScannedContentParser.parse("geo:45.5906,-73.4503?q=Chalet") else {
            Issue.record("Localisation attendue")
            return
        }
        #expect(point.latitude == 45.5906)
        #expect(point.longitude == -73.4503)
        #expect(point.query == "Chalet")
    }

    @Test func roundTripThroughBuilder() throws {
        var wifi = WiFiInput()
        wifi.ssid = "Réseau:Maison"
        wifi.password = "p;a,s\\s"
        let payload = try PayloadBuilder.build(.wifi(wifi))
        guard case .wifi(let network) = ScannedContentParser.parse(payload) else {
            Issue.record("Wi-Fi attendu")
            return
        }
        #expect(network.ssid == wifi.ssid)
        #expect(network.password == wifi.password)
    }
}

@Suite("Sécurité des liens")
struct URLSafetyTests {
    @Test func deceptiveHostIsDecoded() throws {
        let url = try #require(URL(string: "https://xn--pple-43d.com/login"))
        let report = URLSafety.analyze(url)
        #expect(report.displayHost == "аpple.com")
        #expect(report.warnings.contains(.deceptiveCharacters(decodedHost: "аpple.com")))
    }

    @Test func shortenerPaymentAndCredentials() throws {
        #expect(URLSafety.analyze(try #require(URL(string: "https://bit.ly/abc"))).warnings.contains(.shortener))
        #expect(URLSafety.analyze(try #require(URL(string: "https://paypal.me/marie"))).isPayment)
        #expect(URLSafety.analyze(try #require(URL(string: "https://banque.com@pirate.net"))).warnings
            .contains(.embeddedCredentials))
        #expect(URLSafety.analyze(try #require(URL(string: "http://192.168.1.1/"))).warnings
            .contains(.ipAddress))
        #expect(!URLSafety.analyze(try #require(URL(string: "https://www.apple.com/ca/fr/"))).hasWarnings)
    }
}

@Suite("Schémas inhabituels")
struct UnusualSchemeTests {
    @Test func flagsUnusualAndDangerousSchemes() throws {
        let script = try #require(URLSafety.unusualScheme(in: "javascript:alert(1)"))
        #expect(script.scheme == "javascript" && script.isDangerous)
        let store = try #require(URLSafety.unusualScheme(in: "itms-services://?action=download-manifest"))
        #expect(store.scheme == "itms-services" && !store.isDangerous)
        #expect(URLSafety.unusualScheme(in: "https://exemple.com") == nil)
        #expect(URLSafety.unusualScheme(in: "Note: rappeler Marie") == nil)
        #expect(URLSafety.unusualScheme(in: "Bonjour tout le monde") == nil)
    }
}

@Suite("Masquage des secrets")
struct SecretRedactorTests {
    @Test func wifiPasswordIsHidden() {
        #expect(SecretRedactor.redacted("WIFI:T:WPA;S:Maison;P:secret123;H:false;;") == "WIFI:T:WPA;S:Maison;P:•••;H:false;;")
        #expect(SecretRedactor.redacted("WIFI:P:a\\;b;S:Café;;") == "WIFI:P:•••;S:Café;;")
        #expect(SecretRedactor.redacted("WIFI:T:WPA;S:SP:ot;P:x;;") == "WIFI:T:WPA;S:SP:ot;P:•••;;")
        #expect(SecretRedactor.redacted("https://exemple.com/P:1") == "https://exemple.com/P:1")
    }
}

@Suite("Résumé lisible d'une entrée")
struct EntrySummaryTests {
    @Test func summaryNeverShowsWiFiPassword() {
        let wifi = CodeEntry(rawValue: "WIFI:T:WPA;S:Maison;P:secret123;;", symbology: .qr, contentType: .wifi, origin: .scanned)
        #expect(wifi.summary == "Maison")
        let card = CodeEntry(rawValue: "BEGIN:VCARD\nVERSION:3.0\nFN:Marie Tremblay\nORG:Café Temporel\nEND:VCARD",
                             symbology: .qr, contentType: .contact, origin: .scanned)
        #expect(card.summary == "Marie Tremblay · Café Temporel")
        let text = CodeEntry(rawValue: "Bonjour\nle monde", symbology: .qr, contentType: .text, origin: .generated)
        #expect(text.summary == "Bonjour le monde")
    }
}
