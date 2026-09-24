import QRCore
import SwiftData
import SwiftUI

struct MacSidebar: View {
    @Environment(AppServices.self) private var services
    @Query(sort: \Folder.name) private var folders: [Folder]
    @State private var isManagingFolders = false

    var body: some View {
        @Bindable var services = services
        List(selection: $services.sidebar) {
            Section("Bibliothèque") {
                Label("Tous les codes", systemImage: "square.grid.2x2").tag(AppServices.SidebarItem.allCodes)
                Label("Favoris", systemImage: "star").tag(AppServices.SidebarItem.favorites)
                Label("Scannés", systemImage: "camera.viewfinder").tag(AppServices.SidebarItem.scanned)
                Label("Créés", systemImage: "wand.and.stars").tag(AppServices.SidebarItem.generated)
                Label("Carte des scans", systemImage: "map").tag(AppServices.SidebarItem.map)
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
                    .tag(AppServices.SidebarItem.folder(folder.id))
                }
            }
            Section {
                Label("Supprimés récemment", systemImage: "trash").tag(AppServices.SidebarItem.trash)
            }
        }
        .navigationSplitViewColumnWidth(min: 180, ideal: 210)
        .safeAreaInset(edge: .bottom) {
            Button {
                isManagingFolders = true
            } label: {
                Label("Gérer les dossiers", systemImage: "folder.badge.gearshape")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
            .padding(10)
        }
        .sheet(isPresented: $isManagingFolders) {
            NavigationStack { FolderManagerView() }
                .frame(minWidth: 420, minHeight: 420)
        }
    }
}
