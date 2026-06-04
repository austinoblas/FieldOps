import CoreLocation

/// Turns a store's street address into coordinates so events can be geofenced.
enum Geocoder {
    static func coordinates(for address: String) async -> CLLocationCoordinate2D? {
        let trimmed = address.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let placemarks = try? await CLGeocoder().geocodeAddressString(trimmed)
        return placemarks?.first?.location?.coordinate
    }
}
