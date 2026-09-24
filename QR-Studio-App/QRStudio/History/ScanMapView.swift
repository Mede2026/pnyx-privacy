import CoreLocation
import MapKit
import OSLog
import QRCore
import SwiftData
import SwiftUI

/// Carte des scans : un point par lieu, regroupés en grappes quand ils sont proches.
struct ScanMapView: View {
    @Environment(\.modelContext) private var context
    @Environment(AppServices.self) private var services
    @State private var entries: [CodeEntry] = []
    @State private var span: Double = 1
    @State private var selectedCluster: Cluster?
    @State private var typeFilter: ContentType?
    @State private var startDate: Date?
    @State private var endDate: Date?
    @State private var isChoosingDates = false

    struct Cluster: Identifiable {
        let id: String
        let coordinate: CLLocationCoordinate2D
        let entries: [CodeEntry]
    }

    var body: some View {
        Map(initialPosition: .automatic) {
            ForEach(clusters) { cluster in
                Annotation(cluster.entries.count == 1 ? cluster.entries[0].displayTitle : "", coordinate: cluster.coordinate) {
                    Button {
                        selectedCluster = cluster
                    } label: {
                        ZStack {
                            Circle().fill(Color.accentColor)
                            if cluster.entries.count > 1 {
                                Text("\(cluster.entries.count)")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                            } else {
                                Image(systemName: cluster.entries[0].contentKind.symbolName)
                                    .font(.caption)
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(width: cluster.entries.count > 1 ? 36 : 28, height: cluster.entries.count > 1 ? 36 : 28)
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                    }
                    .accessibilityLabel(Text("\(cluster.entries.count) codes"))
                }
            }
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            span = max(context.region.span.latitudeDelta, 0.0005)
        }
        .overlay {
            if entries.isEmpty {
                #if os(macOS)
                ContentUnavailableView("Aucun lieu pour l’instant", systemImage: "map",
                                       description: Text("Les scans faits sur iPhone, avec l’enregistrement du lieu activé, apparaissent ici."))
                #else
                ContentUnavailableView("Aucun lieu pour l’instant", systemImage: "map",
                                       description: Text("Activez « Enregistrer le lieu des scans » dans Réglages pour voir vos scans ici."))
                #endif
            }
        }
        .navigationTitle("Carte des scans")
        .inlineNavigationTitle()
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Section("Période") {
                        Button("Toute la période") { setPeriod(days: nil) }
                        Button("7 derniers jours") { setPeriod(days: 7) }
                        Button("30 derniers jours") { setPeriod(days: 30) }
                        Button("Dernière année") { setPeriod(days: 365) }
                        Button("Choisir des dates…", systemImage: "calendar") { isChoosingDates = true }
                    }
                    Picker("Type", selection: $typeFilter) {
                        Text("Tous les types").tag(ContentType?.none)
                        ForEach(ContentType.allCases) { Text($0.title).tag(ContentType?.some($0)) }
                    }
                } label: {
                    Label("Filtres", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(item: $selectedCluster) { cluster in
            PlaceCodesSheet(cluster: cluster)
        }
        .sheet(isPresented: $isChoosingDates) {
            MapDateRangeSheet(start: $startDate, end: $endDate)
        }
        .task(id: "\(typeFilter?.rawValue ?? "")-\(startDate?.timeIntervalSince1970 ?? 0)-\(endDate?.timeIntervalSince1970 ?? 0)") {
            load()
        }
    }

    /// Regroupement sur une grille dont la maille suit le niveau de zoom.
    private var clusters: [Cluster] {
        let cell = span / 12
        var groups: [String: [CodeEntry]] = [:]
        for entry in entries {
            guard let latitude = entry.latitude, let longitude = entry.longitude else { continue }
            let key = "\(Int((latitude / cell).rounded(.down)))|\(Int((longitude / cell).rounded(.down)))"
            groups[key, default: []].append(entry)
        }
        return groups.map { key, members in
            let latitude = members.compactMap(\.latitude).reduce(0, +) / Double(members.count)
            let longitude = members.compactMap(\.longitude).reduce(0, +) / Double(members.count)
            return Cluster(id: key, coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), entries: members)
        }
    }

    private func setPeriod(days: Int?) {
        startDate = days.flatMap { Calendar.current.date(byAdding: .day, value: -$0, to: .now) }
        endDate = nil
    }

    private func load() {
        let since = startDate.map { Calendar.current.startOfDay(for: $0) } ?? .distantPast
        // Date de fin incluse : jusqu'à la fin de ce jour.
        let until = endDate.flatMap { Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: $0)) }
            ?? .distantFuture
        let type = typeFilter?.rawValue ?? ""
        let anyType = typeFilter == nil
        let descriptor = FetchDescriptor<CodeEntry>(predicate: #Predicate { entry in
            entry.latitude != nil && entry.deletedAt == nil && entry.createdAt >= since && entry.createdAt < until
                && (anyType || entry.contentType == type)
        })
        do {
            entries = try context.fetch(descriptor)
        } catch {
            services.alerts.show(error)
        }
    }
}
