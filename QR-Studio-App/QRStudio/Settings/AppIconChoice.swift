import SwiftUI

/// Icônes proposées dans les réglages. Le nom de l'icône alternative correspond au fichier Resources/AppIcon-….icon.
enum AppIconChoice: String, CaseIterable, Identifiable {
    case standard = "Default"
    case nuit = "Nuit"
    case ocean = "Ocean"
    case menthe = "Menthe"
    case corail = "Corail"

    var id: String { rawValue }

    /// nil = icône principale.
    var alternateIconName: String? {
        self == .standard ? nil : "AppIcon-\(rawValue)"
    }

    var title: LocalizedStringResource {
        switch self {
        case .standard: "Classique"
        case .nuit: "Nuit"
        case .ocean: "Océan"
        case .menthe: "Menthe"
        case .corail: "Corail"
        }
    }

    var preview: Image { Image("IconPreview-\(rawValue)") }

    init(alternateIconName: String?) {
        self = Self.allCases.first { $0.alternateIconName == alternateIconName } ?? .standard
    }
}
