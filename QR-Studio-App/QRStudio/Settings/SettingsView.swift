import QRCore
import SwiftData
import SwiftUI

/// Onglet Réglages.
struct SettingsView: View {
    @Environment(AppServices.self) private var services
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                Picker("Ouvrir automatiquement", selection: $settings.autoOpen) {
                    ForEach(AutoOpenMode.allCases) { Text($0.title).tag($0) }
                }
                Toggle("Scan continu", isOn: $settings.continuousScan)
                Toggle("Son", isOn: $settings.playsSound)
                Toggle("Vibration", isOn: $settings.usesHaptics)
            } header: {
                Text("Scanner")
            } footer: {
                Text("Scan continu : aucune feuille ne s’ouvre, les codes s’empilent dans une liste. Les réseaux Wi-Fi, contacts, événements, adresses de cryptomonnaie et liens de paiement demandent toujours une confirmation.")
            }

            Section {
                Picker("Formats en mode lot", selection: $settings.batchSymbologies) {
                    ForEach(BatchSymbologyPreset.allCases) { Text($0.title).tag($0) }
                }
                if settings.batchSymbologies == .custom {
                    NavigationLink {
                        BatchSymbologiesView()
                    } label: {
                        LabeledContent("Formats choisis", value: "\(settings.customBatchSymbologies.count)")
                    }
                }
                Toggle("Compter les doublons séparément", isOn: $settings.countsDuplicatesSeparately)
            } header: {
                Text("Mode lot")
            } footer: {
                Text("« Produits en magasin » lit seulement EAN-13, EAN-8, UPC-E et Code 128, ce qui est plus rapide.")
            }

            Section("Produits") {
                NavigationLink {
                    SearchSitesView()
                } label: {
                    Label("Sites de recherche", systemImage: "magnifyingglass")
                }
            }

            MacLinkSection()
            WebhookSection()
            PrivacySection()
            SyncSection()
            BackupSection()

            if OnDeviceIntelligence.isAvailable {
                Section {
                    Toggle("Suggérer libellés et dossiers", isOn: $settings.suggestsLabels)
                } header: {
                    Text("Apple Intelligence")
                } footer: {
                    Text("Les suggestions sont faites sur votre appareil. Rien n’est appliqué sans votre accord.")
                }
            }

            Section("App") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link(destination: url) {
                        Label("Langue et autorisations", systemImage: "globe")
                    }
                }
                NavigationLink {
                    AppIconPickerView()
                } label: {
                    Label("Icône de l’app", systemImage: "app.badge")
                }
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label("Confidentialité", systemImage: "hand.raised")
                }
                LabeledContent("Version", value: Bundle.main.appVersion)
            }

            DangerZoneSection()
        }
        .navigationTitle("Réglages")
    }
}

extension Bundle {
    var appVersion: String {
        let version = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
}
