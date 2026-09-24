import QRCore
import SwiftData
import SwiftUI

/// Tout effacer, avec confirmation à double étape.
struct DangerZoneSection: View {
    @Environment(AppServices.self) private var services
    @Environment(\.modelContext) private var context
    @State private var step = 0
    @State private var count = 0

    var body: some View {
        Section {
            Button("Tout effacer", role: .destructive) {
                do {
                    count = try context.fetchCount(FetchDescriptor<CodeEntry>())
                    step = 1
                } catch {
                    services.alerts.show(error)
                }
            }
        } footer: {
            Text("Supprime tous les codes sur tous vos appareils. Faites d’abord une sauvegarde si vous pourriez en avoir besoin.")
        }
        .confirmationDialog("Effacer tout l’historique ?", isPresented: Binding(get: { step == 1 }, set: { if !$0 && step == 1 { step = 0 } }),
                            titleVisibility: .visible) {
            Button("Continuer", role: .destructive) { step = 2 }
        } message: {
            Text("\(count) codes seront supprimés.")
        }
        .alert("En êtes-vous vraiment sûr ?", isPresented: Binding(get: { step == 2 }, set: { if !$0 { step = 0 } })) {
            Button("Annuler", role: .cancel) { step = 0 }
            Button("Effacer \(count) codes", role: .destructive, action: eraseAll)
        } message: {
            Text("Cette action est irréversible et la suppression atteint chaque appareil connecté à votre iCloud.")
        }
    }

    private func eraseAll() {
        step = 0
        do {
            let entries = try context.fetch(FetchDescriptor<CodeEntry>())
            services.store.deletePermanently(entries)
        } catch {
            services.alerts.show(error)
        }
    }
}
