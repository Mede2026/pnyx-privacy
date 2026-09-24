import SwiftUI

/// Résumé de la politique de confidentialité, affiché dans l'app.
struct PrivacyPolicyView: View {
    var body: some View {
        List {
            Section {
                Text("QR Studio est entièrement gratuit : aucun achat intégré, aucun abonnement, aucune publicité et aucun outil d’analyse.")
            }
            Section("Ce qui reste sur vos appareils") {
                Label("Tout ce que vous scannez et créez, stocké sur vos appareils et dans votre iCloud privé.", systemImage: "iphone")
                Label("La caméra analyse le flux vidéo pour lire les codes. Aucune photo n’est prise ni conservée.", systemImage: "camera")
                Label("Le lieu des scans, seulement si vous activez l’option.", systemImage: "location")
            }
            Section("Quand l’app utilise le réseau") {
                Label("L’ouverture d’un lien que vous avez choisi.", systemImage: "link")
                Label("Aperçus en ligne et noms de produits, seulement à votre demande ou si les aperçus sont activés.", systemImage: "text.below.photo")
                Label("Google Safe Browsing, seulement s’il est activé : une liste de préfixes de hachage est téléchargée ; vos liens sont vérifiés sur l’appareil.", systemImage: "shield.lefthalf.filled")
                Label("Envoi vers votre Mac, sur votre réseau local seulement, par une connexion chiffrée.", systemImage: "desktopcomputer")
                Label("Webhook, seulement si vous le configurez : chaque scan est envoyé à l’adresse que vous avez choisie.", systemImage: "arrow.up.right.circle")
            }
            Section {
                Text("Aucune donnée n’est collectée par le développeur.")
                    .font(.headline)
            }
        }
        .navigationTitle("Confidentialité")
    }
}
