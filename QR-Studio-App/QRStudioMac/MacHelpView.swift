import SwiftUI

/// Aide intégrée, en français.
struct MacHelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Aide de QR Studio").font(.largeTitle.bold())
                helpItem("Créer un code", "Fichier › Nouveau code (⌘N). Choisissez le type, remplissez le formulaire : l’aperçu se met à jour et la lisibilité est vérifiée.")
                helpItem("Lire un code dans une image", "Glissez une image sur la fenêtre, ou collez-la. Le code est lu et ajouté à l’historique.")
                helpItem("Scanner avec la caméra", "Fichier › Scanner avec la caméra (⌘K). Vous pouvez choisir votre iPhone comme caméra grâce à Caméra de continuité.")
                helpItem("Exporter", "Sélectionnez un code puis Fichier › Exporter (⌘S) : PNG, JPEG, PDF vectoriel ou SVG.")
                helpItem("Glisser un code", "Glissez l’aperçu d’un code vers le Finder ou une autre app pour y déposer son image.")
                helpItem("Synchronisation", "L’historique se synchronise par votre iCloud privé avec l’iPhone, l’iPad et l’Apple Watch.")
            }
            .padding(24)
        }
        .frame(width: 520, height: 520)
    }

    private func helpItem(_ title: LocalizedStringKey, _ text: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(text).foregroundStyle(.secondary)
        }
    }
}
