import Foundation

/// Types de menaces de l'API v5.
public enum ThreatType: String, Codable, Sendable, CaseIterable {
    case malware = "MALWARE"
    case socialEngineering = "SOCIAL_ENGINEERING"
    case unwantedSoftware = "UNWANTED_SOFTWARE"
    case potentiallyHarmfulApplication = "POTENTIALLY_HARMFUL_APPLICATION"

    /// Ordre de gravité quand un même hachage porte plusieurs menaces (0 = la plus grave).
    var severityRank: Int {
        switch self {
        case .malware: 0
        case .socialEngineering: 1
        case .unwantedSoftware: 2
        case .potentiallyHarmfulApplication: 3
        }
    }

    /// Motif affiché, formulé avec nuance comme l'exige Google.
    public var reason: String {
        switch self {
        case .malware: L("Ce site pourrait installer des logiciels malveillants.")
        case .socialEngineering: L("Ce site pourrait tenter de vous tromper (hameçonnage).")
        case .unwantedSoftware: L("Ce site pourrait proposer des logiciels indésirables.")
        case .potentiallyHarmfulApplication: L("Ce site pourrait proposer des applications dangereuses.")
        }
    }
}
