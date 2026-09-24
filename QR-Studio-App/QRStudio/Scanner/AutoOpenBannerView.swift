import SwiftUI

/// Bannière de 1,5 s avant l'ouverture automatique : l'utilisateur voit où il part et peut arrêter.
struct AutoOpenBannerView: View {
    static let delay: Duration = .milliseconds(1500)

    let state: AutoOpenBannerState
    let onCancel: () -> Void
    let onFire: () -> Void
    @State private var progress: Double = 0

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: state.symbolName)
                .font(.title3)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(state.title)
                    .font(.headline)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(state.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Annuler", role: .cancel, action: onCancel)
                .glassButtonStyle(prominent: true)
        }
        .padding(14)
        .background(alignment: .bottomLeading) {
            GeometryReader { proxy in
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: proxy.size.width * progress, height: 3)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 4)
        }
        .glassRoundedRect(cornerRadius: 22)
        .accessibilityElement(children: .contain)
        .task(id: state.id) {
            Announcer.say("\(state.detail) \(state.title)")
            withAnimation(.linear(duration: 1.5)) { progress = 1 }
            guard await pause(Self.delay) else { return }
            onFire()
        }
    }
}
