//
//  ManualRouteViewModel.swift
//  pathwise
//
//  ViewModel for manual route drawing with finger
//

import Foundation
import SwiftUI
import MapKit
import CoreLocation
import Combine

@MainActor
class ManualRouteViewModel: ObservableObject {
    @Published var currentRoute: ManualRoute?
    @Published var isDrawing = false
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var drawnCoordinates: [CLLocationCoordinate2D] = []

    private let mapMatchingService = MapMatchingService()
    private let locationManager: PathLocationManager
    private let minDistanceBetweenPoints: CLLocationDistance = 5.0 // meters (reduced for better capture)

    init(locationManager: PathLocationManager) {
        self.locationManager = locationManager
    }

    /// Start drawing mode
    func startDrawing() {
        isDrawing = true
        drawnCoordinates = []
        currentRoute = nil
        errorMessage = nil
        print("🖊️ Started drawing mode")
    }

    /// Stop drawing mode
    func stopDrawing() {
        isDrawing = false
    }

    /// Add a coordinate from finger drawing (called during pan gesture)
    func addDrawnCoordinate(_ coordinate: CLLocationCoordinate2D) {
        guard isDrawing else {
            print("⚠️ Not in drawing mode, ignoring coordinate")
            return
        }

        // Only add point if it's far enough from the last point (reduces noise)
        if let lastCoordinate = drawnCoordinates.last {
            let lastLocation = CLLocation(latitude: lastCoordinate.latitude, longitude: lastCoordinate.longitude)
            let newLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            let distance = lastLocation.distance(from: newLocation)

            guard distance >= minDistanceBetweenPoints else {
                return
            }
        }

        drawnCoordinates.append(coordinate)
        print("✏️ Added coordinate #\(drawnCoordinates.count): \(coordinate.latitude), \(coordinate.longitude)")
    }

    /// Snap the drawn path to roads (called when finger lifts)
    func snapToRoads() {
        guard !drawnCoordinates.isEmpty else {
            errorMessage = "Draw a path on the map first"
            return
        }

        guard drawnCoordinates.count >= 2 else {
            errorMessage = "Path is too short. Draw a longer route."
            return
        }

        isProcessing = true
        errorMessage = nil

        print("📍 Snapping \(drawnCoordinates.count) drawn points to roads...")

        Task {
            do {
                let route = try await mapMatchingService.snapToRoads(drawnCoordinates)
                self.currentRoute = route
                self.isDrawing = false
                self.isProcessing = false

                print("✅ Route snapped!")
                print("📏 Distance: \(route.distanceFormatted)")
                print("⏱️ Duration: \(route.durationFormatted)")
            } catch {
                self.errorMessage = error.localizedDescription
                self.isProcessing = false
                print("❌ Snap failed: \(error.localizedDescription)")
            }
        }
    }

    /// Clear the current route and drawn coordinates
    func clearRoute() {
        currentRoute = nil
        drawnCoordinates = []
        isDrawing = false
        errorMessage = nil
    }
}
