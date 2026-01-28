//
//  RoutingService.swift
//  pathwise
//
//  Service for generating loop walking routes using Stadia Maps Routing API
//

import Foundation
import CoreLocation

actor RoutingService {
    private let healthKitService = HealthKitService()
    private let overpassService = OverpassService()
    private var cachedWalkingSpeed: Double?

    // MARK: - Pivot Point Algorithm

    /// Calculates a pivot point for creating a loop route using Haversine formula
    /// - Parameters:
    ///   - start: Starting location coordinate
    ///   - targetDistance: Desired total distance in miles
    /// - Returns: Pivot point coordinate
    static func calculatePivotPoint(from start: CLLocationCoordinate2D, targetDistance: Double) -> CLLocationCoordinate2D {
        // Calculate radius for half the loop distance
        // Using 2.5 factor to account for street winding
        let actualRadius = targetDistance / 2.5

        // Random bearing in degrees (0-360)
        let randomBearing = Double.random(in: 0..<360)

        // Calculate pivot coordinate using Haversine
        return calculateDestination(
            start: start,
            distance: actualRadius,
            bearing: randomBearing
        )
    }

    /// Calculates a destination coordinate given a start point, distance, and bearing
    /// Uses Haversine formula for accurate spherical geometry
    /// - Parameters:
    ///   - start: Starting coordinate
    ///   - distance: Distance in miles
    ///   - bearing: Bearing in degrees (0-360)
    /// - Returns: Destination coordinate
    private static func calculateDestination(
        start: CLLocationCoordinate2D,
        distance: Double,
        bearing: Double
    ) -> CLLocationCoordinate2D {
        let earthRadiusMiles = 3958.8 // Earth's radius in miles

        let lat1 = start.latitude * .pi / 180.0
        let lon1 = start.longitude * .pi / 180.0
        let bearingRad = bearing * .pi / 180.0

        let lat2 = asin(
            sin(lat1) * cos(distance / earthRadiusMiles) +
            cos(lat1) * sin(distance / earthRadiusMiles) * cos(bearingRad)
        )

        let lon2 = lon1 + atan2(
            sin(bearingRad) * sin(distance / earthRadiusMiles) * cos(lat1),
            cos(distance / earthRadiusMiles) - sin(lat1) * sin(lat2)
        )

        return CLLocationCoordinate2D(
            latitude: lat2 * 180.0 / .pi,
            longitude: lon2 * 180.0 / .pi
        )
    }

    // MARK: - Route Fetching

    /// Fetches a loop walking route from Stadia Maps using optimized_route endpoint
    /// - Parameters:
    ///   - startLocation: Starting location
    ///   - miles: Desired distance in miles
    /// - Returns: Generated walking route
    func fetchLoop(from startLocation: CLLocationCoordinate2D, miles: Double) async throws -> WalkingRoute {
        // Strategy: Use Overpass API to find actual residential streets, then place waypoints on them
        let radius = miles / 3.5
        let radiusMeters = radius * 1609.34 // Convert miles to meters

        print("🗺️ Querying OSM for residential streets to place waypoints...")

        // Query Overpass API for residential street points
        let residentialPoints = try await overpassService.findResidentialStreetPoints(
            near: startLocation,
            radiusMeters: radiusMeters
        )

        var waypoints: [[String: Any]] = [
            [
                "lat": startLocation.latitude,
                "lon": startLocation.longitude,
                "type": "break",
                "search_cutoff": 50  // Smaller cutoff since we're already on good streets
            ]
        ]

        if residentialPoints.isEmpty {
            // Fallback to geometric waypoints if Overpass fails
            print("⚠️ No residential streets found via Overpass, falling back to geometric waypoints")
            let startBearing = Double.random(in: 0..<360)

            for i in 1...2 {
                let bearing = (startBearing + Double(i) * 120.0).truncatingRemainder(dividingBy: 360)
                let point = Self.calculateDestination(
                    start: startLocation,
                    distance: radius,
                    bearing: bearing
                )
                waypoints.append([
                    "lat": point.latitude,
                    "lon": point.longitude,
                    "type": "through",
                    "search_cutoff": 200
                ])
            }
        } else {
            // Select 2 waypoints from residential streets spread evenly around the loop
            let selectedPoints = await overpassService.selectWaypoints(
                from: residentialPoints,
                center: startLocation,
                targetRadius: radius,
                count: 2
            )

            for point in selectedPoints {
                waypoints.append([
                    "lat": point.latitude,
                    "lon": point.longitude,
                    "type": "through",  // Flow through residential areas
                    "search_cutoff": 50  // Smaller since already on street
                ])
            }
        }

        // Close the loop
        waypoints.append([
            "lat": startLocation.latitude,
            "lon": startLocation.longitude,
            "type": "break",
            "search_cutoff": 50
        ])

        // Build request body with waypoints forming a triangular loop
        // Strategy: Use correct Valhalla pedestrian costing parameters from official docs
        let requestBody: [String: Any] = [
            "locations": waypoints,
            "costing": "pedestrian",
            "costing_options": [
                "pedestrian": [
                    "walking_speed": 5.1,  // Walking speed in km/h
                    "walkway_factor": 0.1,  // Extremely favor walkways/paths (0.9-6.0 range, lower=better)
                    "sidewalk_factor": 0.1,  // Extremely favor sidewalks (0.9-6.0 range, lower=better)
                    "alley_factor": 2.0,  // Avoid alleys somewhat (0.5-5.0 range, higher=avoid)
                    "driveway_factor": 5.0,  // Strongly avoid driveways (0.5-5.0 range, higher=avoid)
                    "step_penalty": 0.0,  // Don't penalize steps/stairs (0-15 seconds)
                    "use_ferry": 0.0,  // Never use ferries (0-1)
                    "use_living_streets": 1.0,  // Maximum use of living streets (0-1)
                    "use_tracks": 0.5,  // Moderate use of tracks (0-1)
                    "use_hills": 0.5,  // Prefer flatter routes (0-1, lower=avoid hills)
                    "max_hiking_difficulty": 1,  // Only easy paths (0-6)
                    "bss_return_cost": 0,  // Not using bike share
                    "bss_return_penalty": 0,  // Not using bike share
                    "shortest": false,  // Not shortest path
                    "service_penalty": 0.0,  // Don't penalize service roads (0-15 seconds)
                    "service_factor": 0.8  // Actually prefer service roads (0.5-5.0 range, lower=better)
                ]
            ],
            "directions_options": [
                "units": "miles"
            ],
            "shape_format": "polyline6"
        ]

        // Build URL - using optimized_route endpoint for better loop formation
        guard let url = URL(string: "https://api.stadiamaps.com/optimized_route?api_key=\(StadiaMapsConfig.apiKey)") else {
            throw RoutingError.invalidURL
        }

        print("🗺️ Generating loop with \(waypoints.count) waypoints (OSM-guided) using optimized_route")
        print("🗺️ Requested distance: \(miles) miles")
        print("🗺️ Loop radius: \(radius) miles")
        print("🗺️ Waypoints placed on residential streets via Overpass API")
        print("🗺️ Stadia Maps Request URL: \(url.absoluteString)")

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make API request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RoutingError.invalidResponse
        }

        print("🗺️ Stadia Maps Response Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            // Log the error response body for debugging
            if let errorString = String(data: data, encoding: .utf8) {
                print("🗺️ Stadia Maps Error Response: \(errorString)")
            }
            throw RoutingError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let decoder = JSONDecoder()
        let routingResponse = try decoder.decode(StadiaMapsResponse.self, from: data)

        guard let trip = routingResponse.trip else {
            throw RoutingError.noRouteFound
        }

        // Combine all legs into a single route
        var allCoordinates: [CLLocationCoordinate2D] = []
        var totalDistance = 0.0
        var totalTime = 0.0
        var allSteps: [RouteStep] = []

        for (index, leg) in trip.legs.enumerated() {
            // Decode polyline for this leg
            let legCoordinates = decodePolyline6(leg.shape)

            // Skip the first coordinate of subsequent legs to avoid duplicates at waypoints
            if index > 0 && !allCoordinates.isEmpty && !legCoordinates.isEmpty {
                // Check if last coord of previous leg matches first coord of this leg
                let lastCoord = allCoordinates.last!
                let firstCoord = legCoordinates.first!
                let distance = abs(lastCoord.latitude - firstCoord.latitude) + abs(lastCoord.longitude - firstCoord.longitude)

                if distance < 0.0001 { // Very close, skip duplicate
                    allCoordinates.append(contentsOf: legCoordinates.dropFirst())
                } else {
                    allCoordinates.append(contentsOf: legCoordinates)
                }
            } else {
                allCoordinates.append(contentsOf: legCoordinates)
            }

            // Sum distance and time (Valhalla returns km, so convert to miles)
            totalDistance += leg.summary.length * 0.621371 // km to miles
            totalTime += leg.summary.time

            // Collect maneuvers
            let legSteps = leg.maneuvers.map { maneuver -> RouteStep in
                RouteStep(
                    instruction: maneuver.instruction,
                    distance: maneuver.length * 0.621371, // km to miles
                    duration: maneuver.time
                )
            }
            allSteps.append(contentsOf: legSteps)
        }

        // Fetch user's walking speed from HealthKit if not cached
        if cachedWalkingSpeed == nil {
            cachedWalkingSpeed = await healthKitService.fetchAverageWalkingSpeed()
        }

        // Calculate duration using user's pace or HealthKit-adjusted estimate
        let estimatedDuration = await healthKitService.calculateWalkingTime(
            distance: totalDistance,
            userSpeed: cachedWalkingSpeed
        )

        print("🗺️ Route has \(allCoordinates.count) coordinate points")
        print("🗺️ Number of legs: \(trip.legs.count)")
        print("🗺️ First coordinate: \(allCoordinates.first?.latitude ?? 0), \(allCoordinates.first?.longitude ?? 0)")
        print("🗺️ Last coordinate: \(allCoordinates.last?.latitude ?? 0), \(allCoordinates.last?.longitude ?? 0)")
        print("🗺️ Total route distance: \(totalDistance) miles")
        print("🗺️ Stadia time estimate: \(totalTime / 60.0) minutes")
        print("🗺️ HealthKit-adjusted time: \(estimatedDuration) minutes")

        return WalkingRoute(
            coordinates: allCoordinates,
            distance: totalDistance,
            duration: estimatedDuration, // Use HealthKit-adjusted duration
            polyline: trip.legs.first?.shape ?? "",
            steps: allSteps
        )
    }

    /// Calculates distance between two coordinates in miles
    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let location2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return location1.distance(from: location2) * 0.000621371 // meters to miles
    }

    // MARK: - Polyline Decoding

    /// Decodes a polyline6 encoded string into coordinates
    /// - Parameter polyline: Encoded polyline string
    /// - Returns: Array of coordinates
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

// MARK: - Response Models

struct StadiaMapsResponse: Codable {
    let trip: Trip?
}

struct Trip: Codable {
    let legs: [Leg]
    let summary: Summary
}

struct Leg: Codable {
    let shape: String
    let summary: Summary
    let maneuvers: [Maneuver]
}

struct Summary: Codable {
    let length: Double // in miles
    let time: Double // in seconds
}

struct Maneuver: Codable {
    let instruction: String
    let length: Double // in miles
    let time: Double // in seconds
}

// MARK: - Errors

enum RoutingError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case noRouteFound
    case decodingError

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid request URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .apiError(let statusCode):
            return "API error (status code: \(statusCode))"
        case .noRouteFound:
            return "No suitable route found. Try a different distance."
        case .decodingError:
            return "Failed to decode route data"
        }
    }
}
