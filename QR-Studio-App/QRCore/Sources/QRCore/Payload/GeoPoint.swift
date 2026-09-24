import Foundation

public struct GeoPoint: Sendable, Hashable {
    public init(latitude: Double, longitude: Double, query: String? = nil) {
        self.latitude = latitude
        self.longitude = longitude
        self.query = query
    }

    public var latitude: Double
    public var longitude: Double
    public var query: String?
}
