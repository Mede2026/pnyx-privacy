import QRCore
import SwiftData
import SwiftUI

/// Onglet Historique (disposition compacte) : bandeau de dossiers, liste, détail poussé.
struct HistoryScreen: View {
    @Environment(AppRouter.self) private var router
    @Query(sort: \Folder.name) private var folders: [Folder]
    @State private var section: AppRouter.SidebarItem = .allCodes
    @State private var path: [UUID] = []
    @State private var isManagingFolders = false

    var body: some View {
        NavigationStack(path: $path) {
            HistoryListView(filter: HistoryFilter(sidebar: section))
                .id(section)
                .inlineNavigationTitle()
                .topBar { sectionBar }
                .navigationDestination(for: UUID.self) { id in
                    CodeDetailView(entryID: id)
                }
        }
        .onChange(of: router.selectedEntryID, initial: true) { _, id in
            // Ouverture depuis Spotlight ou un raccourci.
            guard let id, router.selectedTab == .history else { return }
            path = [id]
            router.selectedEntryID = nil
        }
        .sheet(isPresented: $isManagingFolders) {
            NavigationStack { FolderManagerView() }
        }
    }

    private var sectionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(.allCodes, Text("Tous"), "square.grid.2x2")
                chip(.favorites, Text("Favoris"), "star")
                chip(.scanned, Text("Scannés"), "camera.viewfinder")
                chip(.generated, Text("Créés"), "wand.and.stars")
                ForEach(folders) { folder in
                    chip(.folder(folder.id), Text(verbatim: folder.name), folder.symbolName,
                         color: RGBAColor(hex: folder.colorHex)?.color)
                }
                Button {
                    isManagingFolders = true
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                }
                .buttonStyle(.bordered)
                .clipShape(Capsule())
                .accessibilityLabel(Text("Gérer les dossiers"))
                chip(.trash, Text("Supprimés récemment"), "trash")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private func chip(_ item: AppRouter.SidebarItem, _ title: Text, _ icon: String,
                      color: Color? = nil) -> some View {
        let isSelected = section == item
        return Button {
            withAnimation(.snappy) { section = item }
        } label: {
            Label { title } icon: { Image(systemName: icon) }
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .foregroundStyle(isSelected ? Color.white : (color ?? .primary))
                .background(isSelected ? (color ?? .accentColor) : Color.secondaryBackground, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
