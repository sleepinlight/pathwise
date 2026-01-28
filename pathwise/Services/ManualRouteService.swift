//
//  ManualRouteService.swift
//  pathwise
//
//  Service for manually-drawn walking routes
//

import Foundation
import CoreLocation

actor ManualRouteService {
    private let healthKitService = HealthKitService()
    private var cachedWalkingSpeed: Double?

    /// User-placed waypoints
    private(set) var waypoints: [CLLocationCoordinate2D] = []

    /// Route segments between waypoints
    private(set) var routeSegments: [[CLLocationCoordinate2D]] = []

    /// Total distance in miles
    private(set) var totalDistance: Double = 0.0

    /// Total duration in minutes
    private(set) var totalDuration: Double = 0.0

    /// Add a waypoint and calculate route to it from the previous waypoint
    /// - Parameter coordinate: The coordinate to add
    /// - Returns: Updated route with all segments
    func addWaypoint(_ coordinate: CLLocationCoordinate2D) async throws -> ManualRoute {
        waypoints.append(coordinate)

        // If this is not the first waypoint, calculate route from previous
        if waypoints.count > 1 {
            let previousWaypoint = waypoints[waypoints.count - 2]
            let segment = try await calculateRouteSegment(from: previousWaypoint, to: coordinate)
            routeSegments.append(segment)
        }

        return try await buildCurrentRoute()
    }

    /// Complete the loop by routing back to the first waypoint
    /// - Returns: Complete loop route
    func completeLoop() async throws -> ManualRoute {
        guard waypoints.count >= 2,
              let firstWaypoint = waypoints.first,
              let lastWaypoint = waypoints.last else {
            throw ManualRouteError.notEnoughWaypoints
        }

        // Don't close if already closed
        let distance = calculateDistance(from: lastWaypoint, to: firstWaypoint)
        if distance > 0.01 { // More than ~50 feet apart
            let closingSegment = try await calculateRouteSegment(from: lastWaypoint, to: firstWaypoint)
            routeSegments.append(closingSegment)
        }

        return try await buildCurrentRoute()
    }

    /// Remove the last waypoint
    func removeLastWaypoint() async throws -> ManualRoute {
        guard !waypoints.isEmpty else {
            throw ManualRouteError.noWaypointsToRemove
        }

        waypoints.removeLast()

        // Remove the corresponding route segment
        if !routeSegments.isEmpty {
            routeSegments.removeLast()
        }

        return try await buildCurrentRoute()
    }

    /// Clear all waypoints and start fresh
    func clear() {
        waypoints.removeAll()
        routeSegments.removeAll()
        totalDistance = 0.0
        totalDuration = 0.0
    }

    /// Calculate a route segment between two points using Valhalla
    private func calculateRouteSegment(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) async throws -> [CLLocationCoordinate2D] {
        let requestBody: [String: Any] = [
            "locations": [
                ["lat": start.latitude, "lon": start.longitude],
                ["lat": end.latitude, "lon": end.longitude]
            ],
            "costing": "pedestrian",
            "costing_options": [
                "pedestrian": [
                    "walking_speed": 5.1,
                    "walkway_factor": 0.1,
                    "sidewalk_factor": 0.1,
                    "use_living_streets": 1.0
                ]
            ],
            "shape_format": "polyline6"
        ]

        guard let url = URL(string: "https://api.stadiamaps.com/route?api_key=\(StadiaMapsConfig.apiKey)") else {
            throw ManualRouteError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw ManualRouteError.routingFailed
        }

        let decoder = JSONDecoder()
        let routingResponse = try decoder.decode(StadiaMapsResponse.self, from: data)

        guard let trip = routingResponse.trip,
              let leg = trip.legs.first else {
            throw ManualRouteError.noRouteFound
        }

        return decodePolyline6(leg.shape)
    }

    /// Build current route from all segments
    private func buildCurrentRoute() async throws -> ManualRoute {
        guard !waypoints.isEmpty else {
            return ManualRoute(
                coordinates: [],
                waypoints: [],
                distance: 0.0,
                duration: 0.0
            )
        }

        // Combine all segments
        var allCoordinates: [CLLocationCoordinate2D] = []
        var distance: Double = 0.0

        for (index, segment) in routeSegments.enumerated() {
            if index > 0 && !allCoordinates.isEmpty && !segment.isEmpty {
                // Skip first coordinate of subsequent segments to avoid duplicates
                let lastCoord = allCoordinates.last!
                let firstCoord = segment.first!
                let dist = abs(lastCoord.latitude - firstCoord.latitude) + abs(lastCoord.longitude - firstCoord.longitude)

                if dist < 0.0001 {
                    allCoordinates.append(contentsOf: segment.dropFirst())
                } else {
                    allCoordinates.append(contentsOf: segment)
                }
            } else {
                allCoordinates.append(contentsOf: segment)
            }

            // Calculate segment distance
            for i in 1..<segment.count {
                distance += calculateDistance(from: segment[i-1], to: segment[i])
            }
        }

        // If only one waypoint, just show that point
        if waypoints.count == 1 {
            allCoordinates = [waypoints[0]]
        }

        totalDistance = distance

        // Fetch walking speed if not cached
        if cachedWalkingSpeed == nil {
            cachedWalkingSpeed = await healthKitService.fetchAverageWalkingSpeed()
        }

        // Calculate duration
        totalDuration = await healthKitService.calculateWalkingTime(
            distance: totalDistance,
            userSpeed: cachedWalkingSpeed
        )

        return ManualRoute(
            coordinates: allCoordinates,
            waypoints: waypoints,
            distance: totalDistance,
            duration: totalDuration
        )
    }

    /// Calculate distance between two coordinates in miles
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let location2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return location1.distance(from: location2) * 0.000621371 // meters to miles
    }

    /// Decode polyline6 encoded string into coordinates
    private func decodePolyline6(_ polyline: String) -> [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        var index = polyline.startIndex
        var lat = 0
        var lng = 0

        while index < polyline.endIndex {
            var result = 0
            var shift = 0
            var byte: Int

            repeat {
                byte = Int(polyline[index].asciiValue ?? 0) - 63
                index = polyline.index(after: index)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20

            let deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            lat += deltaLat

            result = 0
            shift = 0

            repeat {
                byte = Int(polyline[index].asciiValue ?? 0) - 63
                index = polyline.index(after: index)
                result |= (byte & 0x1F) << shift
                shift += 5
            } while byte >= 0x20 && index < polyline.endIndex

            let deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1)
            lng += deltaLng

            let coordinate = CLLocationCoordinate2D(
                latitude: Double(lat) / 1e6,
                longitude: Double(lng) / 1e6
            )
            coordinates.append(coordinate)
        }

        return coordinates
    }
}

// MARK: - Manual Route Model

struct ManualRoute {
    let coordinates: [CLLocationCoordinate2D]
    let waypoints: [CLLocationCoordinate2D]
    let distance: Double
    let duration: Double

    var distanceFormatted: String {
        String(format: "%.1f mi", distance)
    }

    var durationFormatted: String {
        let minutes = Int(duration)
        return "\(minutes) min"
    }

    var isLoop: Bool {
        guard waypoints.count >= 2,
              let first = waypoints.first,
              let last = waypoints.last else {
            return false
        }

        let distance = abs(first.latitude - last.latitude) + abs(first.longitude - last.longitude)
        return distance < 0.0001 // Very close = loop
    }
}

// MARK: - Errors

enum ManualRouteError: LocalizedError {
    case invalidURL
    case routingFailed
    case noRouteFound
    case notEnoughWaypoints
    case noWaypointsToRemove

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid routing URL"
        case .routingFailed:
            return "Failed to calculate route segment"
        case .noRouteFound:
            return "No route found between waypoints"
        case .notEnoughWaypoints:
            return "Add at least 2 waypoints to create a loop"
        case .noWaypointsToRemove:
            return "No waypoints to remove"
        }
    }
}
