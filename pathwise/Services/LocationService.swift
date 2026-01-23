//
//  LocationService.swift
//  pathwise
//
//  Location services for weather
//

import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()

    @Published var currentLocation: CLLocation?
    @Published var locationName: String = "Your Location"
    @Published var hasLocationAccess = false

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: - Authorization
    func requestLocationPermission() async -> Bool {
        let status = locationManager.authorizationStatus

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            await MainActor.run {
                self.hasLocationAccess = true
            }
            return true

        case .notDetermined:
            return await withCheckedContinuation { continuation in
                // Store continuation for callback
                self.authorizationContinuation = continuation
                locationManager.requestWhenInUseAuthorization()
            }

        case .denied, .restricted:
            return false

        @unknown default:
            return false
        }
    }

    // MARK: - Get Location
    func requestLocation() {
        guard hasLocationAccess else {
            // Use mock location if no access
            useMockLocation()
            return
        }

        locationManager.requestLocation()
    }

    // MARK: - Reverse Geocoding
    private func reverseGeocodeLocation(_ location: CLLocation) async {
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)

            if let placemark = placemarks.first {
                let locationName = formatLocationName(from: placemark)

                await MainActor.run {
                    self.locationName = locationName
                }
            }
        } catch {
            print("Geocoding error: \(error)")
            await MainActor.run {
                self.locationName = "Current Location"
            }
        }
    }

    private func formatLocationName(from placemark: CLPlacemark) -> String {
        var components: [String] = []

        // Try city/locality first
        if let locality = placemark.locality {
            components.append(locality)
        } else if let subLocality = placemark.subLocality {
            components.append(subLocality)
        }

        // Add state abbreviation or country for context
        if let state = placemark.administrativeArea {
            components.append(state)
        } else if let country = placemark.country {
            components.append(country)
        }

        // Format: "Mount Pleasant, TX" or "San Francisco, CA"
        return components.joined(separator: ", ")
    }

    // MARK: - Mock Location
    func useMockLocation() {
        // Default to a nice location (can be customized)
        let mockLocation = CLLocation(latitude: 37.7749, longitude: -122.4194) // San Francisco

        currentLocation = mockLocation
        locationName = "San Francisco, CA"
        hasLocationAccess = true

        // Or pick a random city for variety in testing
        let mockCities = [
            (name: "Austin, TX", lat: 30.2672, lon: -97.7431),
            (name: "Portland, OR", lat: 45.5152, lon: -122.6784),
            (name: "Denver, CO", lat: 39.7392, lon: -104.9903),
            (name: "Seattle, WA", lat: 47.6062, lon: -122.3321),
            (name: "Boston, MA", lat: 42.3601, lon: -71.0589)
        ]

        let randomCity = mockCities.randomElement()!
        currentLocation = CLLocation(latitude: randomCity.lat, longitude: randomCity.lon)
        locationName = randomCity.name
    }

    // MARK: - Authorization Continuation
    private var authorizationContinuation: CheckedContinuation<Bool, Never>?
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            hasLocationAccess = true
            authorizationContinuation?.resume(returning: true)
            authorizationContinuation = nil

        case .denied, .restricted:
            hasLocationAccess = false
            authorizationContinuation?.resume(returning: false)
            authorizationContinuation = nil

        case .notDetermined:
            break

        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        currentLocation = location

        // Reverse geocode to get location name
        Task {
            await reverseGeocodeLocation(location)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")

        // Fall back to mock location
        useMockLocation()
    }
}
