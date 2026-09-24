import Foundation

/// Styles prédéfinis d'usine. Tous passent les garde-fous de contraste.
public struct StylePreset: Identifiable, Sendable, Hashable {
    public var id: String
    public var name: String
    public var config: StyleConfig
}
