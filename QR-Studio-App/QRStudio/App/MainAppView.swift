import QRCore
import SwiftData
import SwiftUI

/// Racine réelle de l'app : services partagés injectés dans l'environnement.
struct MainAppView: View {
    @State private var services = AppServices.shared

    var body: some View {
        RootTabView()
            .environment(services)
            .environment(services.settings)
            .environment(services.alerts)
            .environment(services.router)
            .environment(services.scanner)
            .modelContainer(services.container)
    }
}
