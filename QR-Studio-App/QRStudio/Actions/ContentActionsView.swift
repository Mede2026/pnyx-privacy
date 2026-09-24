import NaturalLanguage
import QRCore
import SwiftUI
import Translation

/// Boutons d'action proposés selon le type détecté.
struct ContentActionsView: View {
    let parsed: ParsedContent
    let raw: String
    let actions: ActionHandler
    /// Entrée d'historique : la traduction peut être ajoutée à sa note, sur demande seulement.
    var entry: CodeEntry?
    @State private var isTranslating = false
    @State private var translationSource = ""
    @State private var isConfirmingCrypto = false

    var body: some View {
        VStack(spacing: 8) {
            typeActions
            if case .product = parsed {} else {
                ShareLink(item: raw) {
                    Label("Partager", systemImage: "square.and.arrow.up").frame(maxWidth: .infinity)
                }
                .glassButtonStyle()
                .controlSize(.large)
            }
        }
        .modifier(TranslationSheet(isPresented: $isTranslating, text: translationSource, onSave: saveAction))
        .confirmationDialog("Ouvrir ce paiement dans un portefeuille ?", isPresented: $isConfirmingCrypto, titleVisibility: .visible) {
            if case .crypto = parsed, let url = URL(string: raw) {
                Button("Ouvrir") { actions.openExternally(url) }
            }
        } message: {
            Text("Vérifiez bien l’adresse. Un paiement en cryptomonnaie ne peut pas être annulé.")
        }
    }

    @ViewBuilder
    private var typeActions: some View {
        switch parsed {
        case .url(let url): urlActions(url)
        case .location(let point): locationActions(point)
        case .wifi(let network): wifiActions(network)
        case .contact(let card): contactActions(card)
        case .email(let email):
            primary("Écrire le courriel", "envelope") { actions.compose(email) }
            secondary("Copier l’adresse", "doc.on.doc") { actions.copy(email.to) }
        case .sms(let sms):
            primary("Ouvrir Messages", "message") { actions.sendMessage(sms) }
        case .phone(let number): phoneActions(number)
        case .event(let event):
            primary("Ajouter au calendrier", "calendar.badge.plus") { actions.addEvent(event) }
        case .product:
            EmptyView() // Les actions produit vivent dans la fiche produit.
        case .crypto(let payment):
            primary("Ouvrir dans un portefeuille", "wallet.bifold") { isConfirmingCrypto = true }
            secondary("Copier l’adresse", "doc.on.doc") { actions.copy(payment.address) }
        case .text(let text): textActions(text)
        }
    }

    @ViewBuilder
    private func urlActions(_ url: URL) -> some View {
        primary("Ouvrir", "safari") { actions.openInApp(url) }
        #if os(iOS)
        secondary("Ouvrir dans l’app", "arrow.up.forward.app") { actions.openInInstalledApp(url) }
        secondary("Ouvrir dans Safari", "safari.fill") { actions.openExternally(url) }
        #endif
        secondary("Copier le lien", "link") { actions.copy(url.absoluteString) }
    }

    @ViewBuilder
    private func locationActions(_ point: GeoPoint) -> some View {
        primary("Ouvrir dans Plans", "map") { actions.openInMaps(point) }
        if actions.hasGoogleMaps {
            secondary("Ouvrir dans Google Maps", "globe") { actions.openInGoogleMaps(point) }
        }
    }

    @ViewBuilder
    private func wifiActions(_ network: WiFiNetwork) -> some View {
        if !network.isEnterprise {
            primary("Se connecter à « \(network.ssid) »", "wifi") { actions.join(network) }
        }
        if !network.password.isEmpty {
            secondary("Copier le mot de passe", "key") { actions.copy(network.password) }
        }
    }

    @ViewBuilder
    private func contactActions(_ card: ContactCard) -> some View {
        let translatable = Self.translatableText(of: card)
        primary("Ajouter aux contacts", "person.crop.circle.badge.plus") { actions.addContact(card) }
        choice("Appeler", "phone", values: card.phones) { actions.call($0) }
        choice("Écrire", "envelope", values: card.emails) {
            actions.compose(EmailMessage(to: $0, subject: "", body: ""))
        }
        if Self.needsTranslation(translatable) {
            secondary("Traduire la fiche", "translate") { translate(translatable) }
        }
    }

    @ViewBuilder
    private func phoneActions(_ number: String) -> some View {
        primary("Appeler", "phone") { actions.call(number) }
        secondary("Ajouter aux contacts", "person.crop.circle.badge.plus") {
            var card = ContactCard()
            card.phones = [number]
            actions.addContact(card)
        }
        secondary("Copier", "doc.on.doc") { actions.copy(number) }
    }

    @ViewBuilder
    private func textActions(_ text: String) -> some View {
        primary("Copier", "doc.on.doc") { actions.copy(text) }
        secondary("Rechercher sur le web", "magnifyingglass") { actions.searchWeb(text) }
        if Self.needsTranslation(text) {
            secondary("Traduire", "translate") { translate(text) }
        }
    }

    private func translate(_ text: String) {
        translationSource = text
        isTranslating = true
    }

    private var saveAction: ((String) -> Void)? {
        guard entry != nil else { return nil }
        return { saveTranslation($0) }
    }

    /// Ajoutée à la note seulement quand l'utilisateur le demande, jamais automatiquement.
    private func saveTranslation(_ translated: String) {
        guard let entry else { return }
        entry.note = entry.note.isEmpty ? translated : entry.note + "\n\n" + translated
        AppServices.shared.store.updated([entry])
        actions.toast = String(localized: "Traduction ajoutée à la note")
    }

    /// Plusieurs numéros ou adresses : un menu pour choisir, sinon un simple bouton.
    @ViewBuilder
    private func choice(_ title: LocalizedStringKey, _ icon: String, values: [String],
                        action: @escaping (String) -> Void) -> some View {
        if values.count > 1 {
            Menu {
                ForEach(values, id: \.self) { value in
                    Button(value) { action(value) }
                }
            } label: {
                Label(title, systemImage: icon).frame(maxWidth: .infinity)
            }
            .glassButtonStyle()
            .controlSize(.large)
        } else if let value = values.first {
            secondary(title, icon) { action(value) }
        }
    }

    /// Texte d'une fiche contact qui peut se traduire (jamais un numéro, une adresse courriel ou un lien).
    static func translatableText(of card: ContactCard) -> String {
        ([card.jobTitle, card.organization, card.note] + card.addresses)
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
    }

    private func primary(_ title: LocalizedStringKey, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon).frame(maxWidth: .infinity)
        }
        .glassButtonStyle(prominent: true)
        .controlSize(.large)
    }

    private func secondary(_ title: LocalizedStringKey, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon).frame(maxWidth: .infinity)
        }
        .glassButtonStyle()
        .controlSize(.large)
    }

    /// Le bouton Traduire n'apparaît que si la langue détectée diffère de celle de l'appareil.
    static func needsTranslation(_ text: String) -> Bool {
        if #unavailable(iOS 17.4, macOS 14.4) { return false }
        guard text.count >= 4 else { return false }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let language = recognizer.dominantLanguage,
              let confidence = recognizer.languageHypotheses(withMaximum: 1)[language], confidence > 0.6 else {
            return false
        }
        let device = Locale.current.language.languageCode?.identifier ?? "en"
        return language.rawValue != device
    }
}
