import MapKit
import SwiftUI

/// Latitude et longitude, ou toucher la carte pour placer le point.
struct LocationForm: View {
    @Bindable var model: GeneratorFormModel
    @State private var position: MapCameraPosition = .automatic

    var body: some View {
        TextField("Latitude", text: $model.latitude)
            .fieldKeyboard(.numbersAndPunctuation)
            .font(.body.monospacedDigit())
        TextField("Longitude", text: $model.longitude)
            .fieldKeyboard(.numbersAndPunctuation)
            .font(.body.monospacedDigit())
        MapReader { proxy in
            Map(position: $position) {
                if let coordinate {
                    Marker("", coordinate: coordinate)
                }
            }
            .onTapGesture { point in
                guard let coordinate = proxy.convert(point, from: .local) else { return }
                model.latitude = String(format: "%.6f", coordinate.latitude)
                model.longitude = String(format: "%.6f", coordinate.longitude)
            }
        }
        .frame(height: 240)
        .listRowInsets(EdgeInsets())
        .accessibilityLabel(Text("Carte. Touchez pour placer le point."))
        Text("Touchez la carte pour placer le point.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private var coordinate: CLLocationCoordinate2D? {
        guard let latitude = GeneratorFormModel.number(model.latitude),
              let longitude = GeneratorFormModel.number(model.longitude),
              (-90...90).contains(latitude), (-180...180).contains(longitude) else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
