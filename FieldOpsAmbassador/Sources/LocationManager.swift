import CoreLocation

/// One-shot location fetch for geo-stamped check-in/out. First tap on an
/// undecided device just triggers the permission prompt and returns nil;
/// once authorized, a subsequent call returns the coordinate.
@MainActor
final class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }

    var isDenied: Bool {
        manager.authorizationStatus == .denied || manager.authorizationStatus == .restricted
    }

    func fetch() async -> CLLocationCoordinate2D? {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
            return nil
        case .denied, .restricted:
            return nil
        default:
            return await withCheckedContinuation { cont in
                continuation = cont
                manager.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didUpdateLocations locs: [CLLocation]) {
        let coord = locs.first?.coordinate
        MainActor.assumeIsolated {
            continuation?.resume(returning: coord)
            continuation = nil
        }
    }

    nonisolated func locationManager(_ m: CLLocationManager, didFailWithError error: Error) {
        MainActor.assumeIsolated {
            continuation?.resume(returning: nil)
            continuation = nil
        }
    }
}
