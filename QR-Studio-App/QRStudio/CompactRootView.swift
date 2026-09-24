import QRCore
import SwiftUI

struct CompactRootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            ScannerView()
                .tabItem { Label("Scanner", systemImage: "qrcode.viewfinder") }
                .tag(AppRouter.Tab.scanner)
            GeneratorScreen()
                .tabItem { Label("Créer", systemImage: "plus.square.on.square") }
                .tag(AppRouter.Tab.create)
            HistoryScreen()
                .tabItem { Label("Historique", systemImage: "clock.arrow.circlepath") }
                .tag(AppRouter.Tab.history)
            NavigationStack { SettingsView() }
                .tabItem { Label("Réglages", systemImage: "gearshape") }
                .tag(AppRouter.Tab.settings)
        }
        // En disposition compacte, les réglages sont un onglet et non une feuille.
        .onChange(of: router.isSettingsPresented, initial: true) { _, presented in
            if presented {
                router.selectedTab = .settings
                router.isSettingsPresented = false
            }
        }
    }
}
