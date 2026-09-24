import Foundation
import FoundationModels
import OSLog
import QRCore

/// Modèle de langage embarqué (iOS 26 et plus). Tout ce qu'il fait est un bonus :
/// sans lui, le libellé se tape à la main, la recherche reste par mots-clés,
/// l'avertissement montre le texte officiel et le classement se fait à la main.
enum OnDeviceIntelligence {
    /// Vrai seulement si iOS 26 est présent ET que le modèle est prêt sur cet appareil.
    static var isAvailable: Bool {
        guard #available(iOS 26.0, macOS 26.0, *) else { return false }
        return SystemLanguageModel.default.availability == .available
    }

    /// Préchauffe une session à l'ouverture du scanner, pour éviter un délai visible.
    static func prewarm() {
        guard #available(iOS 26.0, macOS 26.0, *), isAvailable else { return }
        LanguageModelSession().prewarm()
    }

    /// Libellé court et dossier suggéré. On n'envoie que le contenu décodé et les noms de dossiers,
    /// jamais l'historique : la fenêtre de contexte est d'environ 4000 jetons.
    static func suggestLabel(for raw: String, type: ContentType, folders: [String]) async -> (label: String, folder: String?)? {
        guard #available(iOS 26.0, macOS 26.0, *), isAvailable else { return nil }
        // Le mot de passe d'un Wi-Fi n'est jamais confié au modèle.
        let content = String(SecretRedactor.redacted(raw).prefix(800))
        let folderList = folders.prefix(40).joined(separator: ", ")
        let prompt = """
        Content type: \(type.rawValue)
        Decoded content: \(content)
        Existing folders: \(folderList.isEmpty ? "none" : folderList)
        """
        do {
            let session = LanguageModelSession(instructions: """
            You name codes scanned with a QR code app. Write a short, human label (4 words at most) \
            in the user's language (\(Locale.current.language.languageCode?.identifier ?? "en")). \
            Never include passwords. Pick the best folder only among the existing folders, or an empty string.
            """)
            let response = try await session.respond(to: prompt, generating: CodeLabelSuggestion.self)
            let label = response.content.label.trimmingCharacters(in: .whitespacesAndNewlines)
            let folder = response.content.suggestedFolder
            guard !label.isEmpty else { return nil }
            return (label, folders.contains(folder) ? folder : nil)
        } catch {
            Logger.general.info("Suggestion de libellé indisponible : \(error.localizedDescription)")
            return nil
        }
    }

    /// Explique en français clair pourquoi un lien est douteux (imitation de marque, caractères trompeurs,
    /// raccourcisseur). Vient sous le message officiel de Google, jamais à sa place.
    static func explainSuspiciousLink(_ url: URL, report: URLSafetyReport) async -> String? {
        guard #available(iOS 26.0, macOS 26.0, *), isAvailable else { return nil }
        let signals = report.warnings.map { String(describing: $0) }.joined(separator: ", ")
        let prompt = """
        Domain: \(report.host)
        Decoded domain: \(report.displayHost)
        Path: \(String(report.path.prefix(200)))
        Local signals: \(signals.isEmpty ? "none" : signals)
        """
        do {
            let session = LanguageModelSession(instructions: """
            Explain in simple French, in two short sentences, why this web address may be suspicious: \
            look-alike brand names, deceptive characters, shorteners, odd structure. Stay cautious: say it \
            "pourrait" be dangerous, never that it is. Do not invent facts about the site.
            """)
            let response = try await session.respond(to: prompt)
            let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
            return text.isEmpty ? nil : text
        } catch {
            Logger.general.info("Explication du lien indisponible : \(error.localizedDescription)")
            return nil
        }
    }

    /// Recherche en langage naturel : « le code que j'ai scanné au chalet en février » devient des critères.
    static func searchFilter(for sentence: String, today: Date = .now) async -> HistoryFilter? {
        guard #available(iOS 26.0, macOS 26.0, *), isAvailable else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        do {
            let session = LanguageModelSession(instructions: """
            Convert a search request about saved QR codes into search criteria. Today is \(formatter.string(from: today)). \
            Put place names and topics in keywords. Leave fields empty when the request does not mention them.
            """)
            let criteria = try await session.respond(to: String(sentence.prefix(300)), generating: SmartSearchCriteria.self).content
            var filter = HistoryFilter()
            filter.searchText = criteria.keywords
            filter.contentType = ContentType(rawValue: criteria.contentType)
            filter.startDate = formatter.date(from: criteria.startDate)
            filter.endDate = formatter.date(from: criteria.endDate)
            filter.favoritesOnly = criteria.favoritesOnly
            return filter
        } catch {
            Logger.general.info("Recherche intelligente indisponible : \(error.localizedDescription)")
            return nil
        }
    }
}
