import MapKit
import QRCore
import SwiftUI

/// Fiche structurée selon le type détecté, au lieu de la chaîne brute.
struct ContentDetailCard: View {
    let parsed: ParsedContent
    let actions: ActionHandler

    var body: some View {
        switch parsed {
        case .url(let url):
            URLDetailCard(url: url, actions: actions)
        case .wifi(let network):
            CardSection {
                Text(network.ssid)
                    .font(.title2.bold())
                    .textSelection(.enabled)
                LabeledContent("Sécurité", value: securityName(network))
                if network.hidden { LabeledContent("Réseau masqué", value: String(localized: "Oui")) }
                if let identity = network.identity {
                    CopyableRow(title: "Identifiant", value: identity, onCopy: copy)
                }
                if !network.password.isEmpty {
                    CopyableRow(title: "Mot de passe", value: network.password, monospaced: true, isSecret: true, onCopy: copy)
                }
            }
        case .contact(let card):
            CardSection {
                Text(card.displayName).font(.title2.bold())
                if !card.organization.isEmpty { CopyableRow(title: "Organisation", value: card.organization, onCopy: copy) }
                if !card.jobTitle.isEmpty { CopyableRow(title: "Poste", value: card.jobTitle, onCopy: copy) }
                ForEach(card.phones, id: \.self) { CopyableRow(title: "Téléphone", value: $0, onCopy: copy) }
                ForEach(card.emails, id: \.self) { CopyableRow(title: "Courriel", value: $0, onCopy: copy) }
                ForEach(card.addresses, id: \.self) { CopyableRow(title: "Adresse", value: $0, onCopy: copy) }
                ForEach(card.urls, id: \.self) { CopyableRow(title: "Site web", value: $0, onCopy: copy) }
                if !card.note.isEmpty { CopyableRow(title: "Note", value: card.note, onCopy: copy) }
            }
        case .location(let point):
            LocationDetailCard(point: point, actions: actions)
        case .email(let email):
            CardSection {
                CopyableRow(title: "Au", value: email.to, onCopy: copy)
                if !email.subject.isEmpty { CopyableRow(title: "Objet", value: email.subject, onCopy: copy) }
                if !email.body.isEmpty { CopyableRow(title: "Message", value: email.body, onCopy: copy) }
            }
        case .sms(let sms):
            CardSection {
                CopyableRow(title: "Numéro", value: sms.number, onCopy: copy)
                if !sms.body.isEmpty { CopyableRow(title: "Message", value: sms.body, onCopy: copy) }
            }
        case .phone(let number):
            CardSection {
                Text(number).font(.title.bold().monospacedDigit()).textSelection(.enabled)
            }
        case .event(let event):
            EventDetailCard(event: event)
        case .product(let product):
            ProductDetailCard(product: product, actions: actions)
        case .crypto(let payment):
            CardSection {
                LabeledContent("Réseau", value: payment.network.capitalized)
                CopyableRow(title: "Adresse", value: payment.address, monospaced: true, onCopy: copy)
                if let amount = payment.amount { CopyableRow(title: "Montant", value: amount, onCopy: copy) }
            }
        case .text(let text):
            CardSection {
                if let unusual = URLSafety.unusualScheme(in: text) {
                    Label(unusual.isDangerous
                          ? String(localized: "Lien « \(unusual.scheme): » : ce type de lien peut exécuter du code. Ne l’ouvrez pas.")
                          : String(localized: "Lien d’un type inhabituel (« \(unusual.scheme): ») : il pourrait ouvrir une app ou lancer une action."),
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(unusual.isDangerous ? .red : .orange)
                }
                Text(text)
                    .font(.body)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func copy(_ value: String) {
        actions.copy(value)
    }

    private func securityName(_ network: WiFiNetwork) -> String {
        if network.isOpen { return String(localized: "Réseau ouvert") }
        if network.isEnterprise { return "WPA2 Enterprise" + (network.eapMethod.map { " (\($0))" } ?? "") }
        return network.security.isEmpty ? "WPA" : network.security
    }
}
