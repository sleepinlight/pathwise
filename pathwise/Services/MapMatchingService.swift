//
//  MapMatchingService.swift
//  pathwise
//
//  Service for map matching - snaps drawn paths to real roads
//

import Foundation
import CoreLocation

class MapMatchingService {
    private let healthKitService = HealthKitService()

    /// Snap a drawn path to real pedestrian roads using Valhalla's map matching
    func snapToRoads(_ coordinates: [CLLocationCoordinate2D]) async throws -> ManualRoute {
        guard coordinates.count >= 2 else {
            throw MapMatchingError.notEnoughPoints
        }

        // Build the route request using coordinates as waypoints
        // Note: Stadia Maps doesn't have a map matching endpoint, so we use routing with multiple waypoints
        let url = URL(string: "https://api.stadiamaps.com/route/v1?api_key=\(StadiaMapsConfig.apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // Sample coordinates to reasonable number (max 20 waypoints for routing API)
        let sampledCoordinates = sampleCoordinates(coordinates, maxPoints: 20)

        // Build locations array for routing
        let locations = sampledCoordinates.map { coord in
            ["lat": coord.latitude, "lon": coord.longitude]
        }

        let requestBody: [String: Any] = [
            "locations": locations,
            "costing": "pedestrian",
            "directions_options": [
                "units": "miles"
            ],
            "costing_options": [
                "pedestrian": [
                    "use_living_streets": 1.0,
                    "walkway_factor": 0.1,
                    "sidewalk_factor": 0.5
                ]
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        request.httpBody = jsonData

        // Debug: Print request details
        if let jsonString = String(data: jsonData, encoding: .utf8) {
            print("📍 MapMatching: Snapping \(sampledCoordinates.count) coordinates to roads...")
            print("🔍 Request URL: \(url.absoluteString)")
            print("🔍 Request body: \(jsonString.prefix(500))...")
        }

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw MapMatchingError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorString = String(data: data, encoding: .utf8) {
                print("❌ MapMatching API Error: \(errorString)")
            }
            throw MapMatchingError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let matchingResponse = try decoder.decode(MapMatchingResponse.self, from: data)

        guard let trip = matchingResponse.trip,
              let leg = trip.legs.first else {
            throw MapMatchingError.noRouteFound
        }

        // Decode the shape (polyline6 format)
        let routeCoordinates = decodePolyline6(leg.shape)

        // Calculate walking speed (default to 3.1 mph if not available)
        let walkingSpeed = await healthKitService.fetchAverageWalkingSpeed() ?? 3.1

        // Distance is in kilometers, convert to miles
        let distanceMiles = leg.summary.length * 0.621371

        // Calculate duration based on walking speed
        let durationSeconds = (distanceMiles / walkingSpeed) * 3600.0

        print("✅ MapMatching: Snapped route - \(String(format: "%.2f", distanceMiles)) miles, \(Int(durationSeconds / 60)) minutes")

        return ManualRoute(
            coordinates: routeCoordinates,
            waypoints: sampledCoordinates,
            distance: distanceMiles,
            duration: durationSeconds
        )
    }

    /// Sample coordinates to reduce API payload size
    private func sampleCoordinates(_ coordinates: [CLLocationCoordinate2D], maxPoints: Int) -> [CLLocationCoordinate2D] {
        guard coordinates.count > maxPoints else {
            return coordinates
        }

        let step = coordinates.count / maxPoints
        var sampled: [CLLocationCoordinate2D] = []

        for i in stride(from: 0, to: coordinates.count, by: step) {
            sampled.append(coordinates[i])
        }

        // Always include the last point
        if let last = coordinates.last,
           let sampledLast = sampled.last,
           !(sampledLast.latitude == last.latitude && sampledLast.longitude == last.longitude) {
            sampled.append(last)
        }

        return sampled
    }

    /// Decode polyline6 format (Valhalla uses 6 decimal places)
    private func decodePolyline6(_ encoded: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = encoded.startIndex
        var lat = 0
        var lng = 0

        while index < encoded.endIndex {
            var result = 0
            var shift = 0
            var byte: Int

            repeat {
                byte = Int(encoded[index].asciiValue! - 63)
                index = encoded.index(after: index)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20

            let deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lat += deltaLat

            result = 0
            shift = 0

            repeat {
                byte = Int(encoded[index].asciiValue! - 63)
                index = encoded.index(after: index)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20

            let deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1))
            lng += deltaLng

            coordinates.append(CLLocationCoordinate2D(
                latitude: Double(lat) / 1e6,
                longitude: Double(lng) / 1e6
            ))
        }

        return coordinates
    }
}

// MARK: - Response Models

struct MapMatchingResponse: Decodable, Sendable {
    let trip: Trip?

    struct Trip: Decodable, Sendable {
        let legs: [Leg]
    }

    struct Leg: Decodable, Sendable {
        let shape: String
        let summary: Summary
    }

    struct Summary: Decodable, Sendable {
        let length: Double  // kilometers
        let time: Double    // seconds
    }
}

enum MapMatchingError: Error, LocalizedError {
    case notEnoughPoints
    case invalidResponse
    case apiError(statusCode: Int)
    case noRouteFound

    var errorDescription: String? {
        switch self {
        case .notEnoughPoints:
            return "Not enough points to create a route. Draw a longer path."
        case .invalidResponse:
            return "Invalid response from map matching service"
        case .apiError(let code):
            return "Map matching failed with status code: \(code)"
        case .noRouteFound:
            return "Could not snap your path to roads. Try drawing along visible roads."
        }
    }
}
