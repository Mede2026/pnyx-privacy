import QRCore
import SwiftUI

/// Onglet « iPhone » des réglages : appairage et mode de dépôt des scans reçus.
struct MacLinkSettingsView: View {
    @Environment(MacLinkServer.self) private var server
    @Environment(\.openWindow) private var openWindow
    @State private var isConfirmingReset = false

    var body: some View {
        @Bindable var server = server
        Form {
            Section {
                Toggle("Recevoir les scans de l’iPhone", isOn: $server.isEnabled)
                if server.isEnabled {
                    LabeledContent("iPhone connectés", value: "\(server.connectedCount)")
                }
                if let error = server.lastError {
                    Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange)
                }
            } footer: {
                Text("L’iPhone devient un lecteur de codes-barres sans fil : chaque code scanné arrive ici, sur le même réseau local, par une connexion chiffrée.")
            }

            if server.isEnabled {
                Section("Que faire des scans reçus ?") {
                    Picker("Mode", selection: $server.mode) {
                        ForEach(MacLinkServer.Mode.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.radioGroup)
                    if server.mode == .typing {
                        Picker("Après chaque scan", selection: $server.suffix) {
                            ForEach(MacLinkServer.Suffix.allCases) { Text($0.title).tag($0) }
                        }
                        if !KeyboardTyper.isTrusted {
                            Button("Autoriser la frappe automatique…") { KeyboardTyper.requestTrust() }
                            Text("macOS demande l’autorisation Accessibilité pour taper dans d’autres apps (Réglages Système › Confidentialité et sécurité › Accessibilité).")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if server.mode == .list {
                        Button("Afficher les scans reçus") { openWindow(id: "received") }
                    }
                }

                Section("Appairer un iPhone") {
                    if let identity = server.identity {
                        HStack(alignment: .top, spacing: 16) {
                            CodePreview(request: RenderRequest(payload: identity.qrPayload, symbology: .qr), pixelWidth: 500)
                                .frame(width: 180, height: 180)
                                .padding(8)
                                .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Scannez ce code avec QR Studio sur l’iPhone.").font(.headline)
                                Text("Une puce « \(identity.name) » apparaîtra ensuite sur le scanner de l’iPhone. Touchez-la pour activer l’envoi.")
                                    .foregroundStyle(.secondary)
                                Button("Réinitialiser l’appairage…") { isConfirmingReset = true }
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onAppear { server.ensureIdentity() }
        .confirmationDialog("Réinitialiser l’appairage ?", isPresented: $isConfirmingReset) {
            Button("Réinitialiser", role: .destructive) { server.ensureIdentity(reset: true) }
        } message: {
            Text("Les iPhone déjà appairés ne pourront plus envoyer de scans tant qu’ils n’auront pas scanné le nouveau code.")
        }
    }
}
