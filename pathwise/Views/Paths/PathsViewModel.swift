//
//  PathsViewModel.swift
//  pathwise
//
//  View model for path generation and management
//

import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
class PathsViewModel: ObservableObject {
    @Published var locationManager = PathLocationManager()
    @Published var selectedDistance: RouteDistance = .twoMiles
    @Published var generatedRoute: WalkingRoute?
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var mapRegion: MKCoordinateRegion

    init() {
        // Start with a neutral region, will update with user location
        self.mapRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }

    func onAppear() {
        // Start location updates immediately
        locationManager.requestLocationPermission()

        // If already authorized, start updating right away
        if locationManager.authorizationStatus == .authorizedWhenInUse ||
           locationManager.authorizationStatus == .authorizedAlways {
            print("📍 PathsViewModel: Location already authorized, starting updates")
            locationManager.startUpdatingLocation()

            // Try to update map region with any cached location
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.updateMapRegion()
            }
        }
    }

    func updateMapRegion() {
        if let location = locationManager.currentLocation {
            print("📍 PathsViewModel: Updating map region to: \(location.latitude), \(location.longitude)")
            mapRegion = MKCoordinateRegion(
                center: location,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
        } else {
            print("📍 PathsViewModel: No location available yet")
        }
    }

    func generateRoute() {
        guard let currentLocation = locationManager.currentLocation else {
            print("❌ PathsViewModel: No location available")
            errorMessage = "Unable to get your location. Please enable location services."
            return
        }

        print("🚶 PathsViewModel: Generating route from \(currentLocation.latitude), \(currentLocation.longitude) for \(selectedDistance.rawValue) miles")

        Task {
            isGenerating = true
            errorMessage = nil

            do {
                let route = try await RouteGenerationService.generateLoopRoute(
                    from: currentLocation,
                    distance: selectedDistance.rawValue
                )

                print("✅ PathsViewModel: Route generated successfully - \(route.distance) miles")
                self.generatedRoute = route

                // Update map to show the route
                if let firstCoordinate = route.coordinates.first {
                    // Calculate bounding box for all coordinates
                    var minLat = firstCoordinate.latitude
                    var maxLat = firstCoordinate.latitude
                    var minLon = firstCoordinate.longitude
                    var maxLon = firstCoordinate.longitude

                    for coordinate in route.coordinates {
                        minLat = min(minLat, coordinate.latitude)
                        maxLat = max(maxLat, coordinate.latitude)
                        minLon = min(minLon, coordinate.longitude)
                        maxLon = max(maxLon, coordinate.longitude)
                    }

                    let center = CLLocationCoordinate2D(
                        latitude: (minLat + maxLat) / 2,
                        longitude: (minLon + maxLon) / 2
                    )

                    let span = MKCoordinateSpan(
                        latitudeDelta: (maxLat - minLat) * 1.5,
                        longitudeDelta: (maxLon - minLon) * 1.5
                    )

                    self.mapRegion = MKCoordinateRegion(center: center, span: span)
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }

            isGenerating = false
        }
    }

    func clearRoute() {
        generatedRoute = nil
        updateMapRegion()
    }
}
