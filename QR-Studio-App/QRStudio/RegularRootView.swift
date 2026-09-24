import QRCore
import SwiftData
import SwiftUI

/// Disposition large : barre latérale (dossiers), liste au centre, détail à droite.
/// Le scanner s'ouvre en plein écran ; les colonnes se replient d'elles-mêmes quand l'appareil se ferme.
struct RegularRootView: View {
    @Environment(AppRouter.self) private var router

    var body: some View {
        @Bindable var router = router
        NavigationSplitView {
            SidebarView()
        } content: {
            switch router.sidebarSelection {
            case .create:
                GeneratorTypePickerView(style: .list)
            default:
                HistoryListView(filter: HistoryFilter(sidebar: router.sidebarSelection ?? .allCodes))
            }
        } detail: {
            NavigationStack {
                switch router.sidebarSelection {
                case .create:
                    if let type = router.generatorType {
                        GeneratorFormView(type: type).id(type)
                    } else {
                        ContentUnavailableView("Choisissez un type", systemImage: "plus.square.on.square",
                                               description: Text("Choisissez ce que vous voulez encoder."))
                    }
                default:
                    if let id = router.selectedEntryID {
                        CodeDetailView(entryID: id).id(id)
                    } else {
                        ContentUnavailableView("Aucun code sélectionné", systemImage: "qrcode",
                                               description: Text("Choisissez un code dans la liste."))
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $router.isScannerPresented) {
            ScannerView()
                .overlay(alignment: .topTrailing) {
                    Button {
                        router.isScannerPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3.weight(.semibold))
                            .frame(width: 44, height: 44)
                            .glassCircleButton()
                    }
                    .buttonStyle(.plain)
                    .padding()
                    .accessibilityLabel(Text("Fermer le scanner"))
                }
                .alertHost()
        }
        .sheet(isPresented: $router.isSettingsPresented) {
            NavigationStack {
                SettingsView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("OK") { router.isSettingsPresented = false }
                        }
                    }
            }
            .alertHost()
        }
    }
}
