import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let manager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var speedKmh: Double = 0
    @Published var pathCoordinates: [CLLocationCoordinate2D] = []
    @Published var distanceTravelled: Double = 0   // meters
    @Published var compassHeading: CLLocationDirection = 0

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.activityType = .fitness
        manager.allowsBackgroundLocationUpdates = true
        manager.activityType = .automotiveNavigation
        manager.pausesLocationUpdatesAutomatically = false
        manager.requestWhenInUseAuthorization()

        manager.startUpdatingLocation()
        manager.startUpdatingHeading()   // ← enables rotation based on phone orientation
    }

    func resetTrip() {
        pathCoordinates.removeAll()
        distanceTravelled = 0
    }
}

extension LocationManager: CLLocationManagerDelegate {

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

            let segmentDistance = current.distance(from: previous) // meters
            distanceTravelled += segmentDistance
        }
    }

    func locationManager(_ manager: CLLocationManager,
                         didUpdateHeading newHeading: CLHeading) {

        // Use true heading when available, fallback to magnetic
        compassHeading = newHeading.trueHeading > 0 ?
                         newHeading.trueHeading :
                         newHeading.magneticHeading
    }

    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
}
