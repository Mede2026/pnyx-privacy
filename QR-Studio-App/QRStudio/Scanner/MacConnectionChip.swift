import QRCore
import SwiftUI

/// Puce en verre en haut du scanner, visible seulement si un Mac appairé est détecté.
/// Grise : envoi coupé. Verte : chaque scan part vers le Mac. Un état qui change le comportement
/// du scan doit être visible là où il agit.
struct MacConnectionChip: View {
    @Environment(AppServices.self) private var services

    var body: some View {
        let link = services.macLink
        if let mac = link.activeMac ?? link.available.first {
            let isActive = link.activeMac?.id == mac.id
            Button {
                link.toggle(mac)
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(color(isActive: isActive, state: link.state))
                        .frame(width: 9, height: 9)
                    Text(title(mac: mac, isActive: isActive, state: link.state))
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .contentShape(Capsule())
                .glassCapsule()
            }
            .buttonStyle(.plain)
            .accessibilityHint(isActive ? Text("Coupe l’envoi des scans vers le Mac")
                                        : Text("Envoie chaque scan vers le Mac"))
            .transition(.opacity.combined(with: .scale))
        }
    }

    private func color(isActive: Bool, state: MacLinkClient.State) -> Color {
        guard isActive else { return .gray }
        switch state {
        case .connected: return .green
        case .connecting: return .orange
        case .failed: return .red
        case .idle: return .gray
        }
    }

    private func title(mac: MacLinkPairing, isActive: Bool, state: MacLinkClient.State) -> String {
        guard isActive else { return mac.name }
        switch state {
        case .connected: return String(localized: "Connecté au \(mac.name)")
        case .connecting: return String(localized: "Connexion au \(mac.name)…")
        case .failed(let message): return message
        case .idle: return mac.name
        }
    }
}
