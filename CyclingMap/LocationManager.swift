import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var speedKmh: Double = 0
    @Published var pathCoordinates: [CLLocationCoordinate2D] = []
    @Published var distanceTravelled: Double = 0
    @Published var compassHeading: CLLocationDirection = 0

    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false

        // Request Always permission (required for background tracking)
        manager.requestAlwaysAuthorization()

        // Background updates MUST be enabled on the main thread
        DispatchQueue.main.async {
            self.manager.allowsBackgroundLocationUpdates = true
            self.manager.startUpdatingLocation()
            self.manager.startUpdatingHeading()   // arrow orientation only
        }
    }

    func resetTrip() {
        pathCoordinates.removeAll()
        distanceTravelled = 0
    }
}

extension LocationManager: CLLocationManagerDelegate {

    // Optional: start updates once authorized
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {

        if status == .authorizedAlways || status == .authorizedWhenInUse {
            DispatchQueue.main.async {
                self.manager.startUpdatingLocation()
                self.manager.startUpdatingHeading()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {

        guard let location = locations.last else { return }
        currentLocation = location

        // Speed (m/s → km/h)
        let rawSpeed = max(location.speed, 0)
        speedKmh = rawSpeed * 3.6

        // Path tracking
        pathCoordinates.append(location.coordinate)

        // Distance calculation
        if pathCoordinates.count > 1 {
            let lastIndex = pathCoordinates.count - 1
            let previous = CLLocation(latitude: pathCoordinates[lastIndex - 1].latitude,
                                      longitude: pathCoordinates[lastIndex - 1].longitude)
            let current = CLLocation(latitude: pathCoordinates[lastIndex].latitude,
                                     longitude: pathCoordinates[lastIndex].longitude)

            let segmentDistance = current.distance(from: previous)
            distanceTravelled += segmentDistance
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateHeading newHeading: CLHeading) {

        // Use true heading when available, fallback to magnetic
        let heading = newHeading.trueHeading > 0
            ? newHeading.trueHeading
            : newHeading.magneticHeading

        compassHeading = heading
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
}
