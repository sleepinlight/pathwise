//
//  PathwiseMapView.swift
//  pathwise
//
//  MapLibre-based map view for displaying walking routes
//

import SwiftUI
import MapKit
import CoreLocation
import MapLibre

struct PathwiseMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let routeCoordinates: [CLLocationCoordinate2D]
    let startCoordinate: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MLNMapView {
        // Use Stadia Maps Outdoors style (optimized for walking/hiking)
        let styleURL = URL(string: "https://tiles.stadiamaps.com/styles/outdoors.json?api_key=\(StadiaMapsConfig.apiKey)")!
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.delegate = context.coordinator
        mapView.setCenter(region.center, zoomLevel: 14, animated: false)
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ mapView: MLNMapView, context: Context) {
        // Update center if needed
        let currentCenter = mapView.centerCoordinate
        if abs(currentCenter.latitude - region.center.latitude) > 0.001 ||
           abs(currentCenter.longitude - region.center.longitude) > 0.001 {
            mapView.setCenter(region.center, zoomLevel: 14, animated: true)
        }

        // Remove existing route overlays
        let overlays = mapView.overlays
        if !overlays.isEmpty {
            mapView.removeOverlays(overlays)
        }

        // Remove existing annotations
        let annotations = mapView.annotations ?? []
        if !annotations.isEmpty {
            mapView.removeAnnotations(annotations)
        }

        // Add route polyline if available
        if !routeCoordinates.isEmpty {
            let polyline = MLNPolyline(coordinates: routeCoordinates, count: UInt(routeCoordinates.count))
            mapView.add(polyline)
        }

        // Add start marker if available
        if let start = startCoordinate {
            let annotation = MLNPointAnnotation()
            annotation.coordinate = start
            mapView.addAnnotation(annotation)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MLNMapViewDelegate {
        var parent: PathwiseMapView

        init(_ parent: PathwiseMapView) {
            self.parent = parent
        }

        // MLNMapViewDelegate methods
        func mapView(_ mapView: MLNMapView, strokeColorForShapeAnnotation annotation: MLNShape) -> UIColor {
            // Use pathwise green color #718355
            return UIColor(red: 0x71/255.0, green: 0x83/255.0, blue: 0x55/255.0, alpha: 1.0)
        }

        func mapView(_ mapView: MLNMapView, lineWidthForPolylineAnnotation annotation: MLNPolyline) -> CGFloat {
            return 5.0
        }

        func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
            guard annotation is MLNPointAnnotation else { return nil }

            let reuseIdentifier = "StartMarker"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)

            if annotationView == nil {
                annotationView = MLNAnnotationView(reuseIdentifier: reuseIdentifier)
                annotationView?.frame = CGRect(x: 0, y: 0, width: 20, height: 20)

                // Create custom marker
                let markerView = UIView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
                markerView.backgroundColor = UIColor(red: 0x71/255.0, green: 0x83/255.0, blue: 0x55/255.0, alpha: 1.0)
                markerView.layer.cornerRadius = 10
                markerView.layer.borderWidth = 3
                markerView.layer.borderColor = UIColor.white.cgColor
                annotationView?.addSubview(markerView)
            }

            return annotationView
        }
    }
}

// MARK: - Preview

#Preview {
    PathwiseMapView(
        region: .constant(MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )),
        routeCoordinates: [],
        startCoordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    )
}
