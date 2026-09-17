import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    var directionUp: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()

        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator

        // IMPORTANT: Disable MapKit auto-tracking (this stops auto-zoom)
        mapView.userTrackingMode = .none

        // Initial fixed camera
        let camera = MKMapCamera(
            lookingAtCenter: CLLocationCoordinate2D(latitude: 51.0, longitude: -3.8),
            fromDistance: 900,   // FIXED ZOOM LEVEL
            pitch: 60,
            heading: 0
        )
        mapView.setCamera(camera, animated: false)

        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        guard let location = locationManager.currentLocation else { return }

        // Determine heading (course when moving, compass when slow)
        let heading: CLLocationDirection
        if directionUp {
            if location.speed > 0.5 {
                heading = location.course >= 0 ? location.course : uiView.camera.heading
            } else {
                heading = locationManager.compassHeading
            }
        } else {
            heading = 0
        }

        // FIXED CAMERA — only update position + heading, NEVER zoom
        let camera = MKMapCamera(
            lookingAtCenter: location.coordinate,
            fromDistance: 900,   // FIXED ZOOM LEVEL
            pitch: 60,
            heading: heading
        )

        uiView.setCamera(camera, animated: false)

        // Draw trail polyline
        let coords = locationManager.pathCoordinates
        if coords.count > 1 {
            // Remove ONLY old polylines (not user location)
            uiView.overlays.forEach { overlay in
                if overlay is MKPolyline {
                    uiView.removeOverlay(overlay)
                }
            }

            let polyline = MKPolyline(coordinates: coords, count: coords.count)
            uiView.addOverlay(polyline)
        }
    }

    // MARK: - Coordinator
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .systemBlue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
