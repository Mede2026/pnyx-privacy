import QRCore
import SwiftUI

/// Réglages Mac (menu QR Studio › Réglages, ⌘,).
struct MacSettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        TabView {
            Form {
                SyncSection()
                BackupSection()
                DangerZoneSection()
            }
            .formStyle(.grouped)
            .tabItem { Label("Général", systemImage: "gearshape") }

            MacLinkSettingsView()
                .tabItem { Label("iPhone", systemImage: "iphone.gen3.radiowaves.left.and.right") }

            NavigationStack { SearchSitesView() }
                .tabItem { Label("Produits", systemImage: "magnifyingglass") }

            Form {
                Section {
                    Toggle("Aperçus en ligne", isOn: $settings.linkPreviews)
                    Toggle("Vérifier les liens avec Google Safe Browsing", isOn: $settings.safeBrowsing)
                        .onChange(of: settings.safeBrowsing) { AppServices.shared.safeBrowsing.settingChanged() }
                    if settings.safeBrowsing && SafeBrowsingClient.apiKey == nil {
                        Label("Aucune clé API n’est configurée : la vérification des liens est inactive.", systemImage: "info.circle")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                } footer: {
                    Text("Les deux sont désactivés par défaut. Les aperçus récupèrent le titre d’une page et le nom des produits. La vérification télécharge une liste de préfixes de hachage : l’adresse complète n’est jamais envoyée à Google.")
                }
                if OnDeviceIntelligence.isAvailable {
                    Toggle("Suggérer libellés et dossiers", isOn: $settings.suggestsLabels)
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Confidentialité", systemImage: "hand.raised") }

            NavigationStack { PrivacyPolicyView() }
                .tabItem { Label("À propos", systemImage: "info.circle") }
        }
        .frame(width: 600, height: 560)
        .alertHost()
    }
}
