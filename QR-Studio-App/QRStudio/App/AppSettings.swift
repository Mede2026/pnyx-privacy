import Foundation
import Observation
import QRCore

/// Réglages de l'app, enregistrés dans les UserDefaults du groupe d'apps
/// pour être lus aussi par l'extension de partage.
@MainActor
@Observable
final class AppSettings {
    @ObservationIgnored private let defaults: UserDefaults

    var autoOpen: AutoOpenMode { didSet { defaults.set(autoOpen.rawValue, forKey: "autoOpen") } }
    var playsSound: Bool { didSet { defaults.set(playsSound, forKey: "playsSound") } }
    var usesHaptics: Bool { didSet { defaults.set(usesHaptics, forKey: "usesHaptics") } }
    var iCloudSync: Bool { didSet { defaults.set(iCloudSync, forKey: "iCloudSync") } }
    var recordsLocation: Bool { didSet { defaults.set(recordsLocation, forKey: "recordsLocation") } }
    var linkPreviews: Bool { didSet { defaults.set(linkPreviews, forKey: "linkPreviews") } }
    var safeBrowsing: Bool { didSet { defaults.set(safeBrowsing, forKey: "safeBrowsing") } }
    var countsDuplicatesSeparately: Bool { didSet { defaults.set(countsDuplicatesSeparately, forKey: "countsDuplicates") } }
    var batchSymbologies: BatchSymbologyPreset { didSet { defaults.set(batchSymbologies.rawValue, forKey: "batchSymbologies") } }
    var suggestsLabels: Bool { didSet { defaults.set(suggestsLabels, forKey: "suggestsLabels") } }
    /// Scan continu en mode simple : pas de feuille, les résultats s'empilent dans une liste.
    var continuousScan: Bool { didSet { defaults.set(continuousScan, forKey: "continuousScan") } }
    /// Mode webhook : désactivé par défaut.
    var webhookEnabled: Bool { didSet { defaults.set(webhookEnabled, forKey: "webhookEnabled") } }
    var webhookURL: String { didSet { defaults.set(webhookURL, forKey: "webhookURL") } }
    /// Formats choisis à la main pour le mode lot (préréglage « Formats choisis »).
    var customBatchSymbologies: Set<Symbology> {
        didSet { defaults.set(customBatchSymbologies.map(\.rawValue).sorted(), forKey: "customBatchSymbologies") }
    }

    init(defaults: UserDefaults = AppSettings.sharedDefaults) {
        self.defaults = defaults
        defaults.register(defaults: [
            "autoOpen": AutoOpenMode.webLinksOnly.rawValue,
            "playsSound": true,
            "usesHaptics": true,
            "iCloudSync": true,
            "recordsLocation": false,
            "linkPreviews": false,
            "safeBrowsing": false,
            "countsDuplicates": false,
            "batchSymbologies": BatchSymbologyPreset.retail.rawValue,
            "suggestsLabels": true,
            "continuousScan": false,
            "webhookEnabled": false,
            "webhookURL": "",
            "customBatchSymbologies": [Symbology.ean13, .ean8, .upcE, .code128].map(\.rawValue)
        ])
        autoOpen = AutoOpenMode(rawValue: defaults.string(forKey: "autoOpen") ?? "") ?? .webLinksOnly
        playsSound = defaults.bool(forKey: "playsSound")
        usesHaptics = defaults.bool(forKey: "usesHaptics")
        iCloudSync = defaults.bool(forKey: "iCloudSync")
        recordsLocation = defaults.bool(forKey: "recordsLocation")
        linkPreviews = defaults.bool(forKey: "linkPreviews")
        safeBrowsing = defaults.bool(forKey: "safeBrowsing")
        countsDuplicatesSeparately = defaults.bool(forKey: "countsDuplicates")
        batchSymbologies = BatchSymbologyPreset(rawValue: defaults.string(forKey: "batchSymbologies") ?? "") ?? .retail
        suggestsLabels = defaults.bool(forKey: "suggestsLabels")
        continuousScan = defaults.bool(forKey: "continuousScan")
        webhookEnabled = defaults.bool(forKey: "webhookEnabled")
        webhookURL = defaults.string(forKey: "webhookURL") ?? ""
        customBatchSymbologies = Set((defaults.stringArray(forKey: "customBatchSymbologies") ?? []).compactMap(Symbology.init(rawValue:)))
    }

    nonisolated static var sharedDefaults: UserDefaults {
        UserDefaults(suiteName: AppModelContainer.appGroupIdentifier) ?? .standard
    }
}
