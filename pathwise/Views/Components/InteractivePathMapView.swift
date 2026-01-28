//
//  InteractivePathMapView.swift
//  pathwise
//
//  Interactive MapLibre map for finger drawing routes
//

import SwiftUI
import MapKit
import CoreLocation
import MapLibre

struct InteractivePathMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let routeCoordinates: [CLLocationCoordinate2D]
    let drawnCoordinates: [CLLocationCoordinate2D]
    let startCoordinate: CLLocationCoordinate2D?
    let isDrawingMode: Bool
    let onDrawCoordinate: (CLLocationCoordinate2D) -> Void
    let onFinishDrawing: () -> Void

    func makeUIView(context: Context) -> MLNMapView {
        let styleURL = URL(string: "https://tiles.stadiamaps.com/styles/outdoors.json?api_key=\(StadiaMapsConfig.apiKey)")!
        let mapView = MLNMapView(frame: .zero, styleURL: styleURL)
        mapView.delegate = context.coordinator
        mapView.setCenter(region.center, zoomLevel: 14, animated: false)
        mapView.showsUserLocation = true

        // Add pan gesture recognizer for drawing
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        panGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(panGesture)

        // Create sketch layer for temporary drawing
        let sketchLayer = CAShapeLayer()
        sketchLayer.strokeColor = UIColor.lightGray.cgColor
        sketchLayer.lineWidth = 3
        sketchLayer.fillColor = UIColor.clear.cgColor
        sketchLayer.lineCap = .round
        sketchLayer.lineJoin = .round
        mapView.layer.addSublayer(sketchLayer)
        context.coordinator.sketchLayer = sketchLayer

        return mapView
    }

    func updateUIView(_ mapView: MLNMapView, context: Context) {
        context.coordinator.onDrawCoordinate = onDrawCoordinate
        context.coordinator.onFinishDrawing = onFinishDrawing
        context.coordinator.isDrawingMode = isDrawingMode

        // Enable/disable map interaction based on drawing mode
        mapView.isScrollEnabled = !isDrawingMode
        mapView.isZoomEnabled = !isDrawingMode
        mapView.isRotateEnabled = !isDrawingMode

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

        // Add snapped route polyline if available (bold green line)
        if !routeCoordinates.isEmpty {
            var mutableCoordinates = routeCoordinates
            let polyline = MLNPolyline(coordinates: &mutableCoordinates, count: UInt(routeCoordinates.count))
            mapView.add(polyline)
        }

        // Update sketch layer for drawn path (thin grey line)
        if !drawnCoordinates.isEmpty && isDrawingMode {
            let path = UIBezierPath()
            let firstPoint = mapView.convert(drawnCoordinates[0], toPointTo: mapView)
            path.move(to: firstPoint)

            for coordinate in drawnCoordinates.dropFirst() {
                let point = mapView.convert(coordinate, toPointTo: mapView)
                path.addLine(to: point)
            }

            context.coordinator.sketchLayer?.path = path.cgPath
        } else {
            context.coordinator.sketchLayer?.path = nil
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onDrawCoordinate: onDrawCoordinate,
            onFinishDrawing: onFinishDrawing,
            isDrawingMode: isDrawingMode
        )
    }

    class Coordinator: NSObject, MLNMapViewDelegate, UIGestureRecognizerDelegate {
        var onDrawCoordinate: (CLLocationCoordinate2D) -> Void
        var onFinishDrawing: () -> Void
        var isDrawingMode: Bool
        var sketchLayer: CAShapeLayer?
        weak var mapView: MLNMapView?

        init(onDrawCoordinate: @escaping (CLLocationCoordinate2D) -> Void,
             onFinishDrawing: @escaping () -> Void,
             isDrawingMode: Bool) {
            self.onDrawCoordinate = onDrawCoordinate
            self.onFinishDrawing = onFinishDrawing
            self.isDrawingMode = isDrawingMode
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard isDrawingMode, let mapView = gesture.view as? MLNMapView else { return }

            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)

            switch gesture.state {
            case .began, .changed:
                onDrawCoordinate(coordinate)
            case .ended, .cancelled:
                onFinishDrawing()
            default:
                break
            }
        }

        // Allow pan gesture to work alongside MapLibre's gestures
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                              shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return !isDrawingMode
        }

        func mapView(_ mapView: MLNMapView, strokeColorForShapeAnnotation annotation: MLNShape) -> UIColor {
            // Pathwise green for snapped routes
            return UIColor(red: 113/255, green: 131/255, blue: 85/255, alpha: 1.0)
        }

        func mapView(_ mapView: MLNMapView, lineWidthForPolylineAnnotation annotation: MLNPolyline) -> CGFloat {
            return 4
        }

        func mapView(_ mapView: MLNMapView, viewFor annotation: MLNAnnotation) -> MLNAnnotationView? {
            // Return nil for user location to use default MapLibre user location view
            if annotation is MLNUserLocation {
                return nil
            }

            return nil
        }
    }
}
