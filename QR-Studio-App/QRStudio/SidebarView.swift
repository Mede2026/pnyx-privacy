import QRCore
import SwiftData
import SwiftUI

struct SidebarView: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \Folder.name) private var folders: [Folder]
    @State private var isManagingFolders = false

    var body: some View {
        @Bindable var router = router
        List(selection: $router.sidebarSelection) {
            Section {
                Button {
                    router.isScannerPresented = true
                } label: {
                    Label("Scanner", systemImage: "qrcode.viewfinder")
                }
                Label("Créer", systemImage: "plus.square.on.square").tag(AppRouter.SidebarItem.create)
            }
            Section("Bibliothèque") {
                Label("Tous les codes", systemImage: "square.grid.2x2").tag(AppRouter.SidebarItem.allCodes)
                Label("Favoris", systemImage: "star").tag(AppRouter.SidebarItem.favorites)
                Label("Scannés", systemImage: "camera.viewfinder").tag(AppRouter.SidebarItem.scanned)
                Label("Créés", systemImage: "wand.and.stars").tag(AppRouter.SidebarItem.generated)
            }
            Section("Dossiers") {
                ForEach(folders) { folder in
                    Label {
                        Text(folder.name)
                    } icon: {
                        Image(systemName: folder.symbolName)
                            .foregroundStyle(RGBAColor(hex: folder.colorHex)?.color ?? .accentColor)
                    }
                    .badge(folder.activeCount)
                    .tag(AppRouter.SidebarItem.folder(folder.id))
                }
                Button {
                    isManagingFolders = true
                } label: {
                    Label("Gérer les dossiers", systemImage: "folder.badge.gearshape")
                }
            }
            Section {
                Label("Supprimés récemment", systemImage: "trash").tag(AppRouter.SidebarItem.trash)
            }
        }
        .navigationTitle("QR Studio")
        .toolbar {
            ToolbarItem {
                Button {
                    router.isSettingsPresented = true
                } label: {
                    Label("Réglages", systemImage: "gearshape")
                }
            }
        }
        .sheet(isPresented: $isManagingFolders) {
            NavigationStack { FolderManagerView() }
        }
    }
}
