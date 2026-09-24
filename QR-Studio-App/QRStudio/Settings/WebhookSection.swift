import QRCore
import SwiftUI

/// Réglage du mode webhook : chaque scan envoyé en POST JSON vers une adresse choisie.
struct WebhookSection: View {
    @Environment(AppServices.self) private var services
    @Environment(AppSettings.self) private var settings
    @State private var testResult: String?
    @State private var isTesting = false

    var body: some View {
        @Bindable var settings = settings
        Section {
            Toggle("Envoyer chaque scan à une adresse web", isOn: $settings.webhookEnabled)
            if settings.webhookEnabled {
                TextField("https://exemple.com/scans", text: $settings.webhookURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if !settings.webhookURL.isEmpty, WebhookSender.validatedURL(settings.webhookURL) == nil {
                    Label("Utilisez https://, ou http:// seulement sur le réseau local.", systemImage: "exclamationmark.triangle")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
                Button {
                    Task { await test() }
                } label: {
                    if isTesting { ProgressView() } else { Text("Envoyer un essai") }
                }
                .disabled(WebhookSender.validatedURL(settings.webhookURL) == nil || isTesting)
                if let testResult {
                    Text(testResult).font(.footnote).foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Webhook")
        } footer: {
            Text("Désactivé par défaut. Chaque code scanné est envoyé en JSON (contenu, symbologie, type, date) à cette adresse, que vous contrôlez. Rien d’autre n’est envoyé.")
        }
    }

    private func test() async {
        isTesting = true
        defer { isTesting = false }
        do {
            try await services.webhook.sendTest()
            testResult = String(localized: "Essai reçu par le serveur.")
        } catch {
            testResult = error.localizedDescription
        }
    }
}
