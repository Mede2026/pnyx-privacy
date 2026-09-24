import SwiftUI

extension AlertCenter {
    /// Seul l'hôte le plus récent (la feuille du dessus) présente l'alerte :
    /// une vue couverte par une feuille ne peut pas présenter.
    func register(_ id: UUID) { hosts.append(id) }
    func unregister(_ id: UUID) { hosts.removeAll { $0 == id } }
    func isTopHost(_ id: UUID) -> Bool { hosts.last == id }
}

private struct AlertHostModifier: ViewModifier {
    @Environment(AlertCenter.self) private var alerts
    @State private var id = UUID()

    func body(content: Content) -> some View {
        content
            .onAppear { alerts.register(id) }
            .onDisappear { alerts.unregister(id) }
            .alert(
                alerts.current?.title ?? "",
                isPresented: Binding(
                    get: { alerts.current != nil && alerts.isTopHost(id) },
                    set: { if !$0 { alerts.current = nil } }
                ),
                presenting: alerts.current
            ) { _ in
                Button("OK", role: .cancel) { alerts.current = nil }
            } message: { message in
                Text(message.detail)
            }
    }
}

extension View {
    /// À placer à la racine et dans chaque feuille qui peut provoquer une erreur.
    func alertHost() -> some View {
        modifier(AlertHostModifier())
    }
}
