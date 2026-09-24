import QRCore
import SwiftUI

/// Mac appairés : l'iPhone devient un lecteur de codes-barres sans fil pour le Mac.
struct MacLinkSection: View {
    @Environment(AppServices.self) private var services

    var body: some View {
        Section {
            ForEach(services.macLink.pairings) { mac in
                Label(mac.name, systemImage: "desktopcomputer")
                    .swipeActions {
                        Button("Oublier", role: .destructive) { services.macLink.forget(mac) }
                    }
            }
            if services.macLink.pairings.isEmpty {
                Text("Aucun Mac appairé.")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Envoi vers le Mac")
        } footer: {
            Text("Sur le Mac, ouvrez QR Studio › Réglages › iPhone, puis scannez le code d’appairage avec l’iPhone. Une puce apparaît ensuite sur le scanner quand le Mac est sur le même réseau.")
        }
    }
}
