import QRCore
import SwiftData
import SwiftUI

/// Lieu des scans, aperçus en ligne et vérification des liens.
struct PrivacySection: View {
    @Environment(AppServices.self) private var services
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var context
    @State private var isConfirmingClear = false

    var body: some View {
        @Bindable var settings = settings
        Section {
            Toggle("Enregistrer le lieu des scans", isOn: $settings.recordsLocation)
                .onChange(of: settings.recordsLocation) { _, enabled in
                    if enabled { services.location.requestAuthorization() }
                }
            if settings.recordsLocation, services.location.authorization == .denied {
                Label("L’accès à la position est désactivé pour QR Studio dans Réglages.", systemImage: "location.slash")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
            Button("Effacer tous les lieux enregistrés", role: .destructive) { isConfirmingClear = true }
        } header: {
            Text("Localisation")
        } footer: {
            Text("Désactivé par défaut. Les lieux restent dans votre iCloud privé et ne sont jamais envoyés ailleurs.")
        }
        .confirmationDialog("Effacer tous les lieux enregistrés ?", isPresented: $isConfirmingClear, titleVisibility: .visible) {
            Button("Effacer les lieux", role: .destructive, action: clearPlaces)
        } message: {
            Text("Les codes sont conservés ; seuls leurs lieux sont effacés.")
        }

        Section {
            Toggle("Aperçus en ligne", isOn: $settings.linkPreviews)
            Toggle("Vérifier les liens avec Google Safe Browsing", isOn: $settings.safeBrowsing)
                .onChange(of: settings.safeBrowsing) { _, enabled in
                    if enabled {
                        Task { await services.safeBrowsing.refresh() }
                    } else {
                        services.safeBrowsing.disable()
                    }
                }
            if settings.safeBrowsing && !services.safeBrowsing.hasAPIKey {
                Label("Aucune clé API n’est configurée : les liens s’ouvrent dans Safari intégré, qui avertit déjà des sites frauduleux.",
                      systemImage: "info.circle")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Réseau")
        } footer: {
            Text("Les deux sont désactivés par défaut. Les aperçus récupèrent le titre d’une page et le nom des produits. La vérification télécharge une liste de préfixes de hachage : l’adresse complète n’est jamais envoyée à Google.")
        }
    }

    private func clearPlaces() {
        do {
            let entries = try context.fetch(FetchDescriptor<CodeEntry>(predicate: #Predicate { $0.latitude != nil }))
            for entry in entries {
                entry.latitude = nil
                entry.longitude = nil
                entry.placeName = nil
            }
            services.store.updated(entries)
        } catch {
            services.alerts.show(error)
        }
    }
}
