import Foundation
import Observation
import QRCore

/// Ouverture automatique après un scan.
enum AutoOpenMode: String, CaseIterable, Identifiable {
    case never
    case webLinksOnly
    case always

    var id: String { rawValue }

    var title: LocalizedStringResource {
        switch self {
        case .never: "Jamais"
        case .webLinksOnly: "Liens web seulement"
        case .always: "Toujours"
        }
    }
}
