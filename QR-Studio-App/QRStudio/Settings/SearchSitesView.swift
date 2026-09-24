import QRCore
import SwiftData
import SwiftUI

/// Sites de recherche de produit : ajouter, renommer, réordonner, supprimer.
struct SearchSitesView: View {
    @Environment(\.modelContext) private var context
    @Environment(AlertCenter.self) private var alerts
    @Query(sort: \SearchSite.sortOrder) private var sites: [SearchSite]
    @State private var editing: SearchSite?
    @State private var isAdding = false

    var body: some View {
        List {
            Section {
                ForEach(sites) { site in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(site.name)
                            Text(site.urlTemplate)
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Toggle("Activé", isOn: Binding(get: { site.isEnabled }, set: { site.isEnabled = $0; save() }))
                            .labelsHidden()
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { editing = site }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(sites[index]) }
                    save()
                }
                .onMove { source, destination in
                    var ordered = sites
                    ordered.move(fromOffsets: source, toOffset: destination)
                    for (index, site) in ordered.enumerated() { site.sortOrder = index }
                    save()
                }
            } footer: {
                Text("Chaque site est une adresse web contenant {code}, remplacé par le code scanné.")
            }
        }
        .navigationTitle("Sites de recherche")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .primaryAction) { EditButton() }
            ToolbarItem(placement: .bottomBar) {
                Button("Ajouter un site", systemImage: "plus") { isAdding = true }
            }
            #else
            ToolbarItem(placement: .primaryAction) {
                Button("Ajouter un site", systemImage: "plus") { isAdding = true }
            }
            #endif
        }
        .sheet(item: $editing) { site in
            SearchSiteEditor(site: site)
        }
        .sheet(isPresented: $isAdding) {
            SearchSiteEditor(site: nil, nextOrder: (sites.map(\.sortOrder).max() ?? -1) + 1)
        }
    }

    private func save() {
        do {
            try context.save()
        } catch {
            alerts.show(error)
        }
    }
}
