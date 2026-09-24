import CoreSpotlight
import QRCore
import SwiftUI

/// Racine : la disposition dépend uniquement des classes de taille, jamais de l'orientation
/// ni du type d'appareil. Compacte : quatre onglets. Large (iPad, écran intérieur d'un pliable) :
/// barre latérale des dossiers.
struct RootTabView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.scenePhase) private var scenePhase
    @Environment(AppServices.self) private var services
    @Environment(AppRouter.self) private var router
    @Environment(ScannerModel.self) private var scanner

    var body: some View {
        Group {
            if horizontalSizeClass == .regular {
                RegularRootView()
            } else {
                CompactRootView()
            }
        }
        .alertHost()
        #if DEBUG
        .onAppear {
            LaunchTimer.firstScreenAppeared()
            // Captures d'écran : « -QRStudioOpen qrstudio://history » ouvre un écran sans passer par un lien.
            let arguments = ProcessInfo.processInfo.arguments
            if let flag = arguments.firstIndex(of: "-QRStudioOpen"), flag + 1 < arguments.count,
               let url = URL(string: arguments[flag + 1]) {
                DeepLink(url: url)?.open(in: services)
            }
        }
        #endif
        .onOpenURL { url in
            DeepLink(url: url)?.open(in: services)
        }
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            // Résultat Spotlight touché : on ouvre le détail du code.
            if let id = SpotlightIndexer.entryID(from: activity) { router.showEntry(id) }
        }
        // Pliage, dépliage, redimensionnement : le scanner reste à l'écran, dans l'autre disposition.
        .onChange(of: horizontalSizeClass) { old, new in
            if new == .regular, router.selectedTab == .scanner {
                router.isScannerPresented = true
            } else if old == .regular, router.isScannerPresented {
                router.isScannerPresented = false
                router.selectedTab = .scanner
            }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            scanner.isAppActive = phase == .active
            if phase == .active {
                services.spotlight.indexNewEntries(context: services.container.mainContext)
                resumeHandoff()
            }
        }
        .onChange(of: scannerIsVisible, initial: true) { _, visible in
            scanner.isTabActive = visible
            services.location.setActive(visible && services.settings.recordsLocation)
            services.macLink.setBrowsing(visible)
            if visible { OnDeviceIntelligence.prewarm() }
        }
    }

    /// Demande laissée par l'extension de partage.
    private func resumeHandoff() {
        switch AppHandoff.consume() {
        case .generator(let text):
            let isLink = if case .url = ScannedContentParser.parse(text) { true } else { false }
            router.createCode(type: isLink ? .url : .text, prefill: text)
        case .entry(let id):
            router.showEntry(id)
        case nil:
            break
        }
    }

    private var scannerIsVisible: Bool {
        horizontalSizeClass == .regular ? router.isScannerPresented : router.selectedTab == .scanner
    }
}
