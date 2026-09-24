import Foundation
import QRCore

/// Décide si le résultat s'ouvre tout seul. Quatre cas suspendent toujours l'ouverture :
/// lien signalé par Safe Browsing, plusieurs codes visibles (géré par le scanner),
/// action difficile à annuler (Wi-Fi, contact, événement, crypto, paiement) et mode lot.
@MainActor
final class AutoOpener {
    private let settings: AppSettings
    /// Vrai si le lien est signalé comme dangereux (Safe Browsing).
    var safeBrowsing: SafeBrowsingGate?

    init(settings: AppSettings) {
        self.settings = settings
    }

    func shouldAutoOpen(_ entry: CodeEntry, mode: ScanMode) async -> Bool {
        guard mode == .single, settings.autoOpen != .never else { return false }
        let parsed = ScannedContentParser.parse(entry.rawValue, symbology: entry.symbologyKind)
        guard !parsed.requiresConfirmation, let action = primaryAction(for: parsed) else { return false }
        if case .openURL(let url) = action {
            if URLSafety.analyze(url).isPayment { return false }
            // Lien signalé : l'écran d'avertissement passe avant tout.
            if let safeBrowsing, case .unsafe = await safeBrowsing.verdict(for: url) { return false }
            return true
        }
        return settings.autoOpen == .always
    }

    func banner(for entry: CodeEntry) -> AutoOpenBannerState? {
        let parsed = ScannedContentParser.parse(entry.rawValue, symbology: entry.symbologyKind)
        guard let action = primaryAction(for: parsed) else { return nil }
        let title: String
        var detail = ""
        switch action {
        case .openURL(let url):
            title = URLSafety.analyze(url).displayHost
            detail = String(localized: "Ouverture du lien…")
        case .openMaps:
            title = String(localized: "Plans")
            detail = String(localized: "Ouverture du lieu…")
        case .call(let number):
            title = number
            detail = String(localized: "Appel…")
        case .email(let email):
            title = email.to
            detail = String(localized: "Rédaction du courriel…")
        case .sms(let sms):
            title = sms.number
            detail = String(localized: "Ouverture de Messages…")
        case .copy:
            title = String(localized: "Texte")
            detail = String(localized: "Copie…")
        case .productPage(let url):
            title = URLSafety.analyze(url).displayHost
            detail = String(localized: "Ouverture de la fiche produit…")
        }
        return AutoOpenBannerState(entry: entry, title: title, detail: detail,
                                   symbolName: parsed.contentType.symbolName, action: action)
    }

    func primaryAction(for parsed: ParsedContent) -> PrimaryAction? {
        switch parsed {
        case .url(let url): .openURL(url)
        case .location(let point): .openMaps(point)
        case .phone(let number): .call(number)
        case .email(let email): .email(email)
        case .sms(let sms): .sms(sms)
        case .text(let text): .copy(text)
        case .product(let product): product.manufacturerURL.map(PrimaryAction.productPage)
        case .wifi, .contact, .event, .crypto: nil
        }
    }
}
