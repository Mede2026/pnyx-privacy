import Foundation

/// Noms lus par VoiceOver pour les icônes proposées (jamais le nom technique du symbole).
enum SymbolNames {
    static let french: [String: String] = [
        "folder": "Dossier", "creditcard": "Carte", "wifi": "Wi-Fi", "cart": "Panier", "house": "Maison",
        "briefcase": "Travail", "ticket": "Billet", "gift": "Cadeau", "book": "Livre", "fork.knife": "Restaurant",
        "airplane": "Avion", "car": "Voiture", "heart": "Cœur", "star": "Étoile", "tag": "Étiquette",
        "shippingbox": "Colis", "person.2": "Personnes", "building.2": "Entreprise", "graduationcap": "École",
        "pawprint": "Animal", "heart.fill": "Cœur", "star.fill": "Étoile", "phone.fill": "Téléphone",
        "envelope.fill": "Courriel", "cart.fill": "Panier", "house.fill": "Maison", "cup.and.saucer.fill": "Café",
        "music.note": "Musique", "camera.fill": "Appareil photo", "gift.fill": "Cadeau", "leaf.fill": "Feuille",
        "pawprint.fill": "Animal", "bolt.fill": "Éclair", "globe": "Globe"
    ]

    static func name(_ symbol: String) -> String {
        french[symbol] ?? "Icône"
    }
}
