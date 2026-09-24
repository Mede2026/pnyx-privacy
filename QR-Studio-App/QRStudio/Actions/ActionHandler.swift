import Contacts
import EventKit
import Foundation
import MessageUI
import NetworkExtension
import Observation
import OSLog
import QRCore
import UIKit

/// Exécute les actions contextuelles. Une instance par écran qui présente des actions,
/// pour que chaque feuille présente ses propres écrans système.
@MainActor
@Observable
final class ActionHandler {
    var presented: PresentedAction?
    /// Lien signalé par Safe Browsing : l'avertissement rouge passe avant toute ouverture.
    var warning: SafeBrowsingWarning?
    var toast: String?
    var alerts: AlertCenter?

    // MARK: - Liens

    /// Ouvre dans un Safari intégré, qui bénéficie de l'avertissement de site frauduleux de Safari.
    func openInApp(_ url: URL) {
        guard Self.isWebLink(url) else {
            openExternally(url)
            return
        }
        afterSafetyCheck(url) { [weak self] in self?.presented = .safari($0) }
    }

    /// Choix fait sur l'écran d'avertissement : Safari intégré, qui garde sa propre protection.
    func openDespiteWarning(_ url: URL) {
        warning = nil
        Task { [weak self] in
            // Le plein écran d'avertissement doit avoir fini de se fermer.
            guard await pause(.milliseconds(400)) else { return }
            self?.presented = .safari(url)
        }
    }

    func openExternally(_ url: URL) {
        afterSafetyCheck(url) { [weak self] in self?.openWithSystem($0) }
    }

    /// Tout lien web passe par Safe Browsing (si activé) avant de s'ouvrir, d'où qu'il vienne :
    /// feuille de scan, historique, fiche produit.
    private func afterSafetyCheck(_ url: URL, then open: @escaping @MainActor (URL) -> Void) {
        let gate = AppServices.shared.safeBrowsing
        guard Self.isWebLink(url), gate.isEnabled, gate.hasAPIKey else {
            open(url)
            return
        }
        Task { [weak self] in
            if case .unsafe(let threat) = await gate.verdict(for: url) {
                self?.warning = SafeBrowsingWarning(url: url, threat: threat)
            } else {
                open(url)
            }
        }
    }

    private static func isWebLink(_ url: URL) -> Bool {
        ["http", "https"].contains(url.scheme?.lowercased() ?? "")
    }

    private func openWithSystem(_ url: URL) {
        UIApplication.shared.open(url) { [weak self] success in
            guard !success else { return }
            Task { @MainActor in
                self?.alerts?.show(title: String(localized: "Ouverture impossible"),
                                   detail: String(localized: "Aucune app de cet appareil ne peut ouvrir ce lien."))
            }
        }
    }

    /// Ouvre seulement si une app installée gère ce lien universel.
    func openInInstalledApp(_ url: URL) {
        afterSafetyCheck(url) { [weak self] in self?.openUniversalLink($0) }
    }

    private func openUniversalLink(_ url: URL) {
        UIApplication.shared.open(url, options: [.universalLinksOnly: true]) { [weak self] success in
            guard !success else { return }
            Task { @MainActor in
                self?.alerts?.show(title: String(localized: "Aucune app pour ce lien"),
                                   detail: String(localized: "Aucune app installée ne gère ce lien. Ouvrez-le plutôt dans Safari."))
            }
        }
    }

    // MARK: - Localisation

    func openInMaps(_ point: GeoPoint) {
        let coordinates = "\(PayloadBuilder.coordinate(point.latitude)),\(PayloadBuilder.coordinate(point.longitude))"
        var components = URLComponents(string: "http://maps.apple.com/")
        components?.queryItems = [URLQueryItem(name: "ll", value: coordinates)]
        if let query = point.query { components?.queryItems?.append(URLQueryItem(name: "q", value: query)) }
        if let url = components?.url { openExternally(url) }
    }

    var hasGoogleMaps: Bool {
        guard let url = URL(string: "comgooglemaps://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    func openInGoogleMaps(_ point: GeoPoint) {
        let coordinates = "\(PayloadBuilder.coordinate(point.latitude)),\(PayloadBuilder.coordinate(point.longitude))"
        if let url = URL(string: "comgooglemaps://?q=\(coordinates)&center=\(coordinates)") { openExternally(url) }
    }

    // MARK: - Communication

    func call(_ number: String) {
        let digits = number.filter { $0.isNumber || $0 == "+" }
        if let url = URL(string: "tel:\(digits)") { openExternally(url) }
    }

    func compose(_ email: EmailMessage) {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email.to
        var items: [URLQueryItem] = []
        if !email.subject.isEmpty { items.append(URLQueryItem(name: "subject", value: email.subject)) }
        if !email.body.isEmpty { items.append(URLQueryItem(name: "body", value: email.body)) }
        components.queryItems = items.isEmpty ? nil : items
        if let url = components.url { openExternally(url) }
    }

    func sendMessage(_ sms: SMSMessage) {
        if MFMessageComposeViewController.canSendText() {
            presented = .message(recipient: sms.number, body: sms.body)
        } else if let url = URL(string: "sms:\(sms.number.filter { $0.isNumber || $0 == "+" })") {
            openExternally(url)
        }
    }

    // MARK: - Wi-Fi

    /// Connexion directe (capability Hotspot Configuration). À défaut, copie du mot de passe.
    func join(_ network: WiFiNetwork) {
        let configuration: NEHotspotConfiguration
        if network.isOpen {
            configuration = NEHotspotConfiguration(ssid: network.ssid)
        } else {
            configuration = NEHotspotConfiguration(ssid: network.ssid, passphrase: network.password,
                                                   isWEP: network.security.uppercased() == "WEP")
        }
        configuration.hidden = network.hidden
        NEHotspotConfigurationManager.shared.apply(configuration) { [weak self] error in
            Task { @MainActor in
                guard let self else { return }
                if let error = error as NSError?,
                   error.code != NEHotspotConfigurationError.alreadyAssociated.rawValue {
                    Logger.actions.error("Connexion Wi-Fi impossible : \(error.localizedDescription)")
                    if !network.password.isEmpty { self.copy(network.password, announce: false) }
                    self.alerts?.show(
                        title: String(localized: "Connexion automatique impossible"),
                        detail: network.password.isEmpty
                            ? error.localizedDescription
                            : String(localized: "Le mot de passe a été copié. Collez-le dans Réglages › Wi-Fi.")
                    )
                } else {
                    self.toast = String(localized: "Connecté à \(network.ssid)")
                }
            }
        }
    }

    // MARK: - Contacts et calendrier

    func addContact(_ card: ContactCard) {
        let contact = CNMutableContact()
        contact.givenName = card.firstName
        contact.familyName = card.lastName
        if card.firstName.isEmpty && card.lastName.isEmpty { contact.givenName = card.fullName }
        contact.organizationName = card.organization
        contact.jobTitle = card.jobTitle
        contact.note = card.note
        contact.phoneNumbers = card.phones.map { CNLabeledValue(label: CNLabelPhoneNumberMobile, value: CNPhoneNumber(stringValue: $0)) }
        contact.emailAddresses = card.emails.map { CNLabeledValue(label: CNLabelWork, value: $0 as NSString) }
        contact.urlAddresses = card.urls.map { CNLabeledValue(label: CNLabelURLAddressHomePage, value: $0 as NSString) }
        contact.postalAddresses = card.addresses.map { line in
            let address = CNMutablePostalAddress()
            address.street = line
            return CNLabeledValue(label: CNLabelWork, value: address)
        }
        presented = .contact(contact)
    }

    /// EKEventEditViewController s'exécute hors du processus : aucune autorisation n'est requise.
    func addEvent(_ calendarEvent: CalendarEvent) {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.title = calendarEvent.title
        event.location = calendarEvent.location
        event.notes = calendarEvent.notes
        event.startDate = calendarEvent.start ?? .now
        event.endDate = calendarEvent.end ?? event.startDate.addingTimeInterval(3600)
        event.isAllDay = calendarEvent.isAllDay
        presented = .event(event, store)
    }

    // MARK: - Action principale (ouverture automatique)

    func perform(_ action: PrimaryAction) {
        switch action {
        case .openURL(let url), .productPage(let url): openInApp(url)
        case .openMaps(let point): openInMaps(point)
        case .call(let number): call(number)
        case .email(let email): compose(email)
        case .sms(let sms): sendMessage(sms)
        case .copy(let text): copy(text)
        }
    }

    // MARK: - Texte

    func copy(_ text: String, announce: Bool = true) {
        UIPasteboard.general.string = text
        if announce { toast = String(localized: "Copié") }
    }

    func searchWeb(_ text: String) {
        // Recherche avec le moteur choisi par l'utilisateur dans Safari.
        let query = text.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? ""
        if let url = URL(string: "x-web-search://?\(query)") { openExternally(url) }
    }
}
