import SwiftUI

/// Caméra refusée ou absente : jamais d'écran noir, toujours une explication et une issue.
struct CameraUnavailableView: View {
    enum Reason {
        case denied
        case noCamera
    }

    let reason: Reason
    let onPickPhoto: () -> Void
    let onPaste: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: reason == .denied ? "camera.badge.ellipsis" : "camera.metering.unknown")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(reason == .denied ? "L’accès à la caméra est désactivé" : "Aucune caméra disponible")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text(reason == .denied
                 ? "QR Studio utilise la caméra uniquement pour lire les codes. Aucune photo n’est jamais prise. Vous pouvez autoriser l’accès dans Réglages."
                 : "Vous pouvez quand même scanner un code depuis une photo ou une image du presse-papier.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            VStack(spacing: 12) {
                if reason == .denied, let url = URL(string: UIApplication.openSettingsURLString) {
                    Link(destination: url) {
                        Label("Ouvrir Réglages", systemImage: "gear")
                            .frame(maxWidth: .infinity)
                    }
                    .glassButtonStyle(prominent: true)
                    .controlSize(.large)
                }
                Button(action: onPickPhoto) {
                    Label("Scanner une photo", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .glassButtonStyle()
                .controlSize(.large)
                Button(action: onPaste) {
                    Label("Scanner l’image du presse-papier", systemImage: "doc.on.clipboard")
                        .frame(maxWidth: .infinity)
                }
                .glassButtonStyle()
                .controlSize(.large)
            }
            .frame(maxWidth: 360)
            Spacer()
            Spacer()
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.appBackground)
    }
}
