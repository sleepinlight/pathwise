//
//  RouteGenerationService.swift
//  pathwise
//
//  Service for generating loop walking routes using Mapbox Directions API
//

import Foundation
import CoreLocation

class RouteGenerationService {
    // MARK: - Pivot Point Algorithm

    /// Calculates a pivot point for creating a loop route
    /// - Parameters:
    ///   - start: Starting location coordinate
    ///   - targetDistance: Desired total distance in miles
    /// - Returns: Pivot point coordinate
    static func calculatePivotPoint(from start: CLLocationCoordinate2D, targetDistance: Double) -> CLLocationCoordinate2D {
        // Calculate radius accounting for:
        // - Route goes out and back (divide by 2)
        // - Street winding factor adds ~60% more distance (divide by 1.6)
        // Combined: targetDistance / 2 / 1.6 = targetDistance / 3.2
        let actualRadius = targetDistance / 3.2

        // Random bearing in degrees (0-360)
        let randomBearing = Double.random(in: 0..<360)

        // Calculate pivot coordinate
        return calculateDestination(
            start: start,
            distance: actualRadius,
            bearing: randomBearing
        )
    }

    /// Calculates a destination coordinate given a start point, distance, and bearing
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

    // MARK: - API Request

    /// Generates a loop route using the Mapbox Directions API
    /// - Parameters:
    ///   - startLocation: Starting location
    ///   - distance: Desired distance in miles
    /// - Returns: Generated walking route
    static func generateLoopRoute(
        from startLocation: CLLocationCoordinate2D,
        distance: Double
    ) async throws -> WalkingRoute {
        // Calculate pivot point
        let pivotPoint = calculatePivotPoint(from: startLocation, targetDistance: distance)

        // Construct coordinates string: start -> pivot -> start
        let coordinatesString = "\(startLocation.longitude),\(startLocation.latitude);" +
                                "\(pivotPoint.longitude),\(pivotPoint.latitude);" +
                                "\(startLocation.longitude),\(startLocation.latitude)"

        // Build URL with parameters
        guard var urlComponents = URLComponents(string: "\(MapboxConfig.directionsAPIBaseURL)/\(MapboxConfig.profile)/\(coordinatesString)") else {
            throw RouteGenerationError.invalidURL
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "geometries", value: "polyline6"),
            URLQueryItem(name: "steps", value: "true"),
            URLQueryItem(name: "overview", value: "full"),
            URLQueryItem(name: "continue_straight", value: "false"),
            URLQueryItem(name: "exclude", value: "ferry"),
            URLQueryItem(name: "walkway_bias", value: "1.0"),
            URLQueryItem(name: "access_token", value: MapboxConfig.accessToken)
        ]

        print("🗺️ Pivot Point: \(pivotPoint.latitude), \(pivotPoint.longitude)")
        print("🗺️ Distance from start to pivot: \(calculateDistance(from: startLocation, to: pivotPoint)) miles")

        guard let url = urlComponents.url else {
            throw RouteGenerationError.invalidURL
        }

        print("🗺️ Mapbox Request URL: \(url.absoluteString)")

        // Make API request
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RouteGenerationError.invalidResponse
        }

        print("🗺️ Mapbox Response Status: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            // Log the error response body for debugging
            if let errorString = String(data: data, encoding: .utf8) {
                print("🗺️ Mapbox Error Response: \(errorString)")
            }
            throw RouteGenerationError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let decoder = JSONDecoder()
        let directionsResponse = try decoder.decode(MapboxDirectionsResponse.self, from: data)

        guard let route = directionsResponse.routes.first else {
            throw RouteGenerationError.noRouteFound
        }

        // Decode polyline
        let coordinates = decodePolyline6(route.geometry)

        print("🗺️ Route has \(coordinates.count) coordinate points")
        print("🗺️ First coordinate: \(coordinates.first?.latitude ?? 0), \(coordinates.first?.longitude ?? 0)")
        print("🗺️ Last coordinate: \(coordinates.last?.latitude ?? 0), \(coordinates.last?.longitude ?? 0)")
        print("🗺️ Route distance: \(route.distance * 0.000621371) miles")

        // Convert to WalkingRoute
        let steps = route.legs?.first?.steps?.compactMap { step -> RouteStep? in
            guard let instruction = step.maneuver?.instruction else { return nil }
            return RouteStep(
                instruction: instruction,
                distance: step.distance * 0.000621371, // meters to miles
                duration: step.duration
            )
        }

        return WalkingRoute(
            coordinates: coordinates,
            distance: route.distance * 0.000621371, // meters to miles
            duration: route.duration / 60.0, // seconds to minutes
            polyline: route.geometry,
            steps: steps
        )
    }

    /// Calculates distance between two coordinates in miles
    private static func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let location2 = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return location1.distance(from: location2) * 0.000621371 // meters to miles
    }

    // MARK: - Polyline Decoding

    /// Decodes a polyline6 encoded string into coordinates
    /// - Parameter polyline: Encoded polyline string
    /// - Returns: Array of coordinates
    private static func decodePolyline6(_ polyline: String) -> [CLLocationCoordinate2D] {
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

// MARK: - Errors

enum RouteGenerationError: LocalizedError {
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
