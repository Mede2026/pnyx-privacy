import CloudKit
import OSLog
import QRCore
import SwiftUI

/// Synchro iCloud (CloudKit privé) et effacement des données envoyées.
struct SyncSection: View {
    @Environment(AppServices.self) private var services
    @Environment(AppSettings.self) private var settings
    @State private var isConfirmingErase = false
    @State private var isErasing = false

    var body: some View {
        Section {
            Toggle("Synchro iCloud", isOn: Binding(get: { settings.iCloudSync }, set: { services.setCloudSync($0) }))
            Button(role: .destructive) {
                isConfirmingErase = true
            } label: {
                if isErasing {
                    ProgressView()
                } else {
                    Text("Effacer les données iCloud")
                }
            }
            .disabled(isErasing)
        } header: {
            Text("iCloud")
        } footer: {
            Text("Votre historique se synchronise par votre iCloud privé entre iPhone, iPad, Mac et Apple Watch. Si vous coupez la synchro, les données déjà envoyées restent sur iCloud jusqu’à ce que vous les effaciez.")
        }
        .confirmationDialog("Effacer les données de QR Studio sur iCloud ?", isPresented: $isConfirmingErase, titleVisibility: .visible) {
            Button("Effacer d’iCloud", role: .destructive) {
                Task { await eraseCloudData() }
            }
        } message: {
            Text("La copie sur cet appareil est conservée. Vos autres appareils perdront leur historique synchronisé.")
        }
    }

    /// Supprime la zone CloudKit utilisée par SwiftData.
    private func eraseCloudData() async {
        isErasing = true
        defer { isErasing = false }
        let database = CKContainer(identifier: AppModelContainer.cloudKitContainerIdentifier).privateCloudDatabase
        let zone = CKRecordZone.ID(zoneName: "com.apple.coredata.cloudkit.zone", ownerName: CKCurrentUserDefaultName)
        do {
            try await database.deleteRecordZone(withID: zone)
            if settings.iCloudSync { services.setCloudSync(false) }
            services.alerts.show(title: String(localized: "Données iCloud effacées"),
                                 detail: String(localized: "La synchro est désactivée. Votre historique est toujours sur cet appareil."))
        } catch {
            services.alerts.show(error, title: String(localized: "Les données iCloud n’ont pas pu être effacées"))
        }
    }
}
