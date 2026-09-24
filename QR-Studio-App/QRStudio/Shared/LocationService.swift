import CoreLocation
import Foundation
import Observation
import OSLog

/// Lieu du scan : désactivé par défaut, WhenInUse demandé seulement quand l'utilisateur active
/// l'option, position approximative acceptée. Les coordonnées ne quittent jamais le CloudKit privé.
@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private(set) var authorization: CLAuthorizationStatus = .notDetermined
    private(set) var lastLocation: CLLocation?
    private var isUpdating = false

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authorization = manager.authorizationStatus
    }

    var isAuthorized: Bool {
        authorization == .authorizedWhenInUse || authorization == .authorizedAlways
    }

    func requestAuthorization() {
        if authorization == .notDetermined { manager.requestWhenInUseAuthorization() }
    }

    /// Mise à jour seulement pendant que le scanner est visible.
    func setActive(_ active: Bool) {
        guard isAuthorized else { return }
        if active, !isUpdating {
            manager.startUpdatingLocation()
            isUpdating = true
        } else if !active, isUpdating {
            manager.stopUpdatingLocation()
            isUpdating = false
        }
    }

    /// Position récente (moins de 2 minutes), sinon rien.
    var recentLocation: CLLocation? {
        guard let lastLocation, Date.now.timeIntervalSince(lastLocation.timestamp) < 120 else { return nil }
        return lastLocation
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in self.authorization = status }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in self.lastLocation = location }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Logger.general.info("Position indisponible : \(error.localizedDescription)")
    }
}
