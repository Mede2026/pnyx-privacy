import AppKit
import Foundation
import Observation
import OSLog
import QRCore

/// Actions contextuelles sur Mac : mêmes méthodes que sur iPhone, réalisées avec les apps du Mac.
@MainActor
@Observable
final class ActionHandler {
    var toast: String?
    var alerts: AlertCenter?

    /// Google Maps n'a pas d'app Mac : le lien web suffit, proposé comme second choix.
    var hasGoogleMaps: Bool { true }

    func openInApp(_ url: URL) { openLink(url) }
    func openExternally(_ url: URL) { openLink(url) }
    func openInInstalledApp(_ url: URL) { openLink(url) }

    func openInMaps(_ point: GeoPoint) {
        var components = URLComponents(string: "https://maps.apple.com/")
        components?.queryItems = [URLQueryItem(name: "ll", value: coordinates(point))]
        if let query = point.query { components?.queryItems?.append(URLQueryItem(name: "q", value: query)) }
        if let url = components?.url { open(url) }
    }

    func openInGoogleMaps(_ point: GeoPoint) {
        if let url = URL(string: "https://www.google.com/maps?q=\(coordinates(point))") { open(url) }
    }

    /// Sur Mac, tel: ouvre FaceTime (ou l'iPhone relié).
    func call(_ number: String) {
        if let url = URL(string: "tel:\(number.filter { $0.isNumber || $0 == "+" })") { open(url) }
    }

    func compose(_ email: EmailMessage) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email.to
        var items: [URLQueryItem] = []
        if !email.subject.isEmpty { items.append(URLQueryItem(name: "subject", value: email.subject)) }
        if !email.body.isEmpty { items.append(URLQueryItem(name: "body", value: email.body)) }
        components.queryItems = items.isEmpty ? nil : items
        if let url = components.url { open(url) }
    }

    func sendMessage(_ sms: SMSMessage) {
        let number = sms.number.filter { $0.isNumber || $0 == "+" }
        let body = sms.body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        if let url = URL(string: "sms:\(number)\(body.isEmpty ? "" : "&body=\(body)")") { open(url) }
    }

    /// Le Mac ne rejoint pas un réseau depuis une app sans autorisations étendues : on copie le mot de passe.
    func join(_ network: WiFiNetwork) {
        copy(network.password, announce: false)
        alerts?.show(title: String(localized: "Mot de passe copié"),
                     detail: String(localized: "Choisissez « \(network.ssid) » dans le menu Wi-Fi et collez le mot de passe."))
    }

    /// Ouvre une fiche .vcf : Contacts propose de l'ajouter.
    func addContact(_ card: ContactCard) {
        var input = ContactInput()
        input.firstName = card.firstName.isEmpty && card.lastName.isEmpty ? card.fullName : card.firstName
        input.lastName = card.lastName
        input.organization = card.organization
        input.phone = card.phones.first ?? ""
        input.email = card.emails.first ?? ""
        input.street = card.addresses.first ?? ""
        input.website = card.urls.first ?? ""
        do {
            let vcard = try PayloadBuilder.build(.contact(input))
            openTemporaryFile(Data(vcard.utf8), name: card.displayName, fileExtension: "vcf")
        } catch {
            alerts?.show(error)
        }
    }

    /// Ouvre un fichier .ics : Calendrier propose d'ajouter l'événement.
    func addEvent(_ event: CalendarEvent) {
        var input = EventInput()
        input.title = event.title.isEmpty ? String(localized: "Événement") : event.title
        input.location = event.location
        input.notes = event.notes
        input.start = event.start ?? .now
        input.end = event.end ?? input.start.addingTimeInterval(3600)
        do {
            let vevent = try PayloadBuilder.build(.event(input))
            let calendar = ["BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//QR Studio//FR", vevent, "END:VCALENDAR"]
                .joined(separator: "\r\n")
            openTemporaryFile(Data(calendar.utf8), name: input.title, fileExtension: "ics")
        } catch {
            alerts?.show(error)
        }
    }

    func copy(_ text: String, announce: Bool = true) {
        Pasteboard.copy(text)
        if announce { toast = String(localized: "Copié") }
    }

    func searchWeb(_ text: String) {
        let query = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        if let url = URL(string: "https://www.google.com/search?q=\(query)") { open(url) }
    }

    /// Lien venant d'un code : vérifié par Safe Browsing si l'option est active.
    private func openLink(_ url: URL) {
        AppServices.shared.safeBrowsing.open(url) { [weak self] in self?.open($0) }
    }

    private func open(_ url: URL) {
        if !NSWorkspace.shared.open(url) {
            alerts?.show(title: String(localized: "Ouverture impossible"),
                         detail: String(localized: "Aucune app de ce Mac ne peut ouvrir ce lien."))
        }
    }

    private func coordinates(_ point: GeoPoint) -> String {
        "\(PayloadBuilder.coordinate(point.latitude)),\(PayloadBuilder.coordinate(point.longitude))"
    }

    private func openTemporaryFile(_ data: Data, name: String, fileExtension: String) {
        let safe = name.components(separatedBy: CharacterSet(charactersIn: "/\\:")).joined(separator: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(safe.isEmpty ? "QR Studio" : safe).appendingPathExtension(fileExtension)
        do {
            try data.write(to: url, options: .atomic)
            open(url)
        } catch {
            alerts?.show(error)
        }
    }
}
