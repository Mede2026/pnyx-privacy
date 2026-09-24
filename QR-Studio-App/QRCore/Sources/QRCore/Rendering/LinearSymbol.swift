import Foundation

/// Symbole linéaire prêt à dessiner : suite de modules, barres de garde allongées, textes.
struct LinearSymbol: Sendable, Equatable {
    struct Caption: Sendable, Equatable {
        var text: String
        /// Plage de modules sous laquelle le texte est centré (peut déborder dans la zone silencieuse).
        var from: Double
        var to: Double
        var small: Bool = false
    }

    var modules: [Bool]
    /// Modules dont la barre descend plus bas (gardes EAN et UPC).
    var guards: [Bool]
    var captions: [Caption]
    var quietLeft: Int
    var quietRight: Int
    /// Vrai pour EAN/UPC : les chiffres se logent entre les gardes.
    var digitsBetweenGuards: Bool
}
