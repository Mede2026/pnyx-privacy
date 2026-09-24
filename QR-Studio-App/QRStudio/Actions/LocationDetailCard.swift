import MapKit
import QRCore
import SwiftUI

struct LocationDetailCard: View {
    let point: GeoPoint
    let actions: ActionHandler

    var body: some View {
        let coordinate = CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
        CardSection {
            Map(initialPosition: .region(MKCoordinateRegion(center: coordinate, latitudinalMeters: 800, longitudinalMeters: 800))) {
                Marker(point.query ?? String(localized: "Localisation"), coordinate: coordinate)
            }
            .frame(height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .allowsHitTesting(false)
            CopyableRow(title: "Coordonnées",
                        value: "\(PayloadBuilder.coordinate(point.latitude)), \(PayloadBuilder.coordinate(point.longitude))",
                        monospaced: true, onCopy: { actions.copy($0) })
        }
    }
}
