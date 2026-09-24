import CoreLocation
import MapKit
import OSLog
import QRCore
import SwiftData
import SwiftUI

/// Codes scannés en un lieu, avec le nom du lieu obtenu par géocodage inverse (mis en cache).
struct PlaceCodesSheet: View {
    let cluster: ScanMapView.Cluster
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss
    @State private var placeName: String?

    var body: some View {
        NavigationStack {
            List(cluster.entries.sorted { $0.createdAt > $1.createdAt }) { entry in
                #if os(macOS)
                // Sur Mac, le code s'affiche dans la colonne de détail de la fenêtre.
                Button {
                    services.selectedEntryID = entry.id
                    dismiss()
                } label: {
                    HistoryRow(entry: entry)
                }
                .buttonStyle(.plain)
                #else
                NavigationLink {
                    CodeDetailView(entryID: entry.id)
                } label: {
                    HistoryRow(entry: entry)
                }
                #endif
            }
            .navigationTitle(placeName ?? String(localized: "\(cluster.entries.count) codes"))
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { dismiss() }
                }
            }
        }
        .sheetHeight(.mediumAndLarge)
        .task { await resolvePlaceName() }
    }

    private func resolvePlaceName() async {
        if let cached = cluster.entries.compactMap(\.placeName).first {
            placeName = cached
            return
        }
        let location = CLLocation(latitude: cluster.coordinate.latitude, longitude: cluster.coordinate.longitude)
        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return }
            let name = [placemark.name, placemark.locality].compactMap { $0 }.joined(separator: ", ")
            placeName = name
            for entry in cluster.entries where entry.placeName == nil { entry.placeName = name }
            services.store.updated(cluster.entries)
        } catch {
            Logger.general.info("Géocodage inverse impossible : \(error.localizedDescription)")
        }
    }
}
