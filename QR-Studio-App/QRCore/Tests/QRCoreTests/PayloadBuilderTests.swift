import Foundation
import Testing
@testable import QRCore

@Suite("PayloadBuilder : chaque type produit la chaîne exacte")
struct PayloadBuilderTests {
    @Test func text() throws {
        #expect(try PayloadBuilder.build(.text("Bonjour à tous")) == "Bonjour à tous")
        #expect(throws: PayloadError.empty) { try PayloadBuilder.build(.text("")) }
    }

    @Test func urlAddsHTTPS() throws {
        #expect(try PayloadBuilder.build(.url("exemple.com")) == "https://exemple.com")
        #expect(try PayloadBuilder.build(.url("http://exemple.com/a?b=1")) == "http://exemple.com/a?b=1")
        #expect(throws: PayloadError.invalidURL) { try PayloadBuilder.build(.url("pas une url")) }
    }

    @Test func wifi() throws {
        var wifi = WiFiInput()
        wifi.ssid = "MonReseau"
        wifi.password = "motdepasse"
        #expect(try PayloadBuilder.build(.wifi(wifi)) == "WIFI:T:WPA;S:MonReseau;P:motdepasse;H:false;;")

        wifi.ssid = "Café;Wi:Fi"
        wifi.password = "a\\b,c\"d"
        wifi.hidden = true
        #expect(try PayloadBuilder.build(.wifi(wifi)) == #"WIFI:T:WPA;S:Café\;Wi\:Fi;P:a\\b\,c\"d;H:true;;"#)

        wifi.security = .none
        wifi.ssid = "Libre"
        #expect(try PayloadBuilder.build(.wifi(wifi)) == "WIFI:T:nopass;S:Libre;H:true;;")
    }

    @Test func enterpriseWiFi() throws {
        var wifi = EnterpriseWiFiInput()
        wifi.ssid = "Bureau"
        wifi.identity = "jdoe"
        wifi.password = "secret"
        #expect(try PayloadBuilder.build(.wifiEnterprise(wifi)) == "WIFI:T:WPA2-EAP;S:Bureau;U:jdoe;P:secret;E:PEAP;;")
    }

    @Test func vCard() throws {
        var contact = ContactInput()
        contact.firstName = "Marie"
        contact.lastName = "Tremblay"
        contact.phone = "+1 (514) 555-0123"
        contact.email = "marie@exemple.ca"
        contact.organization = "Studio, Inc."
        contact.city = "Montréal"
        contact.website = "exemple.ca"
        let expected = [
            "BEGIN:VCARD", "VERSION:3.0", "N:Tremblay;Marie;;;", "FN:Marie Tremblay",
            "ORG:Studio\\, Inc.", "TEL;TYPE=CELL:+15145550123", "EMAIL;TYPE=INTERNET:marie@exemple.ca",
            "ADR;TYPE=WORK:;;;Montréal;;;", "URL:https://exemple.ca", "END:VCARD"
        ].joined(separator: "\r\n")
        #expect(try PayloadBuilder.build(.contact(contact)) == expected)
    }

    @Test func location() throws {
        #expect(try PayloadBuilder.build(.location(latitude: 45.5906, longitude: -73.4503)) == "geo:45.5906,-73.4503")
        #expect(throws: PayloadError.invalidCoordinates) {
            try PayloadBuilder.build(.location(latitude: 95, longitude: 0))
        }
    }

    @Test func email() throws {
        var email = EmailInput()
        email.recipient = "a@b.com"
        email.subject = "Salut & bienvenue"
        email.body = "Ligne 1\nLigne 2"
        #expect(try PayloadBuilder.build(.email(email))
                == "mailto:a@b.com?subject=Salut%20%26%20bienvenue&body=Ligne%201%0ALigne%202")
        email.subject = ""
        email.body = ""
        #expect(try PayloadBuilder.build(.email(email)) == "mailto:a@b.com")
    }

    @Test func smsAndPhone() throws {
        #expect(try PayloadBuilder.build(.sms(number: "+1 514-555-0123", message: "Mon message"))
                == "SMSTO:+15145550123:Mon message")
        #expect(try PayloadBuilder.build(.phone("+1 514 555 0123")) == "tel:+15145550123")
        #expect(throws: PayloadError.invalidPhone) { try PayloadBuilder.build(.phone("abc")) }
    }

    @Test func event() throws {
        var event = EventInput()
        event.title = "Réunion; équipe"
        event.location = "Salle 3"
        event.start = Date(timeIntervalSince1970: 1_789_819_200) // 2026-09-19 12:00:00 UTC
        event.end = event.start.addingTimeInterval(5400)
        event.notes = "Apporter café"
        let expected = [
            "BEGIN:VEVENT", "SUMMARY:Réunion\\; équipe", "LOCATION:Salle 3",
            "DTSTART:20260919T120000Z", "DTEND:20260919T133000Z", "DESCRIPTION:Apporter café", "END:VEVENT"
        ].joined(separator: "\r\n")
        #expect(try PayloadBuilder.build(.event(event)) == expected)
    }

    @Test func social() throws {
        #expect(try PayloadBuilder.build(.social(platform: .instagram, username: "@qrstudio")) == "https://www.instagram.com/qrstudio")
        #expect(try PayloadBuilder.build(.social(platform: .tiktok, username: "qrstudio")) == "https://www.tiktok.com/@qrstudio")
        #expect(try PayloadBuilder.build(.social(platform: .linkedin, username: "marie")) == "https://www.linkedin.com/in/marie")
    }

    @Test func crypto() throws {
        #expect(try PayloadBuilder.build(.crypto(network: .bitcoin, address: "bc1qxyz", amount: "0,01"))
                == "bitcoin:bc1qxyz?amount=0.01")
        #expect(try PayloadBuilder.build(.crypto(network: .bitcoin, address: "bc1qxyz", amount: "")) == "bitcoin:bc1qxyz")
        #expect(try PayloadBuilder.build(.crypto(network: .ethereum, address: "0xABC", amount: "1.5"))
                == "ethereum:0xABC?value=1500000000000000000")
        #expect(throws: PayloadError.invalidAmount) {
            try PayloadBuilder.build(.crypto(network: .bitcoin, address: "bc1q", amount: "abc"))
        }
    }

    @Test func product() throws {
        #expect(try PayloadBuilder.build(.product("4006381333931")) == "4006381333931")
        #expect(try PayloadBuilder.build(.product("4006 3813 3393 1")) == "4006381333931")
        #expect(throws: PayloadError.self) { try PayloadBuilder.build(.product("4006381333932")) }
        #expect(throws: PayloadError.self) { try PayloadBuilder.build(.product("123")) }
    }
}
