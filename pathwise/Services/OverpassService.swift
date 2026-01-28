//
//  OverpassService.swift
//  pathwise
//
//  Service for querying OpenStreetMap via Overpass API to find residential streets
//

import Foundation
import CoreLocation

actor OverpassService {

    /// Queries Overpass API for residential streets within a radius
    /// - Parameters:
    ///   - center: Center coordinate to search around
    ///   - radiusMeters: Search radius in meters
    /// - Returns: Array of coordinates on residential streets
    func findResidentialStreetPoints(near center: CLLocationCoordinate2D, radiusMeters: Double) async throws -> [CLLocationCoordinate2D] {
        // Build Overpass QL query to find residential and living streets
        // We want ways (roads) tagged as highway=residential or highway=living_street
        let query = """
        [out:json][timeout:25];
        (
          way["highway"="residential"](around:\(Int(radiusMeters)),\(center.latitude),\(center.longitude));
          way["highway"="living_street"](around:\(Int(radiusMeters)),\(center.latitude),\(center.longitude));
          way["highway"="tertiary"]["surface"="paved"](around:\(Int(radiusMeters)),\(center.latitude),\(center.longitude));
        );
        out geom;
        """

        // Overpass API endpoint
        guard let url = URL(string: "https://overpass-api.de/api/interpreter") else {
            throw OverpassError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "data=\(query)".data(using: .utf8)
        request.timeoutInterval = 30

        print("🗺️ Querying Overpass API for residential streets within \(Int(radiusMeters))m")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OverpassError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OverpassError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        let decoder = JSONDecoder()
        let overpassResponse = try decoder.decode(OverpassResponse.self, from: data)

        print("🗺️ Found \(overpassResponse.elements.count) residential street segments")

        // Extract coordinates from ways
        var streetPoints: [CLLocationCoordinate2D] = []

        for element in overpassResponse.elements {
            guard element.type == "way", let geometry = element.geometry else { continue }

            // Sample points along each way (not all nodes, just a few per street)
            let step = max(1, geometry.count / 3)  // Get ~3 points per street
            for i in stride(from: 0, to: geometry.count, by: step) {
                let node = geometry[i]
                streetPoints.append(CLLocationCoordinate2D(latitude: node.lat, longitude: node.lon))
            }
        }

        print("🗺️ Extracted \(streetPoints.count) potential waypoint locations on residential streets")

        return streetPoints
    }

    /// Selects optimal waypoints from residential street points to form a loop
    /// - Parameters:
    ///   - streetPoints: Available points on residential streets
    ///   - center: Starting location
    ///   - targetRadius: Desired loop radius
    ///   - count: Number of waypoints to select
    /// - Returns: Selected waypoint coordinates
    func selectWaypoints(from streetPoints: [CLLocationCoordinate2D], center: CLLocationCoordinate2D, targetRadius: Double, count: Int) -> [CLLocationCoordinate2D] {
        guard !streetPoints.isEmpty else { return [] }

        // Calculate distances from center for all points
        let pointsWithDistance = streetPoints.map { point -> (point: CLLocationCoordinate2D, distance: Double) in
            let location1 = CLLocation(latitude: center.latitude, longitude: center.longitude)
            let location2 = CLLocation(latitude: point.latitude, longitude: point.longitude)
            let distanceMiles = location2.distance(from: location1) * 0.000621371
            return (point, distanceMiles)
        }

        // Filter to points roughly at target radius (within ±30%)
        let minRadius = targetRadius * 0.7
        let maxRadius = targetRadius * 1.3
        let candidatePoints = pointsWithDistance.filter { $0.distance >= minRadius && $0.distance <= maxRadius }

        guard !candidatePoints.isEmpty else {
            print("⚠️ No residential streets at target radius, using closest available")
            // Fall back to closest points if nothing at target radius
            let sorted = pointsWithDistance.sorted { $0.distance < $1.distance }
            return Array(sorted.prefix(count).map { $0.point })
        }

        print("🗺️ Found \(candidatePoints.count) candidate waypoints at ~\(targetRadius) mile radius")

        // Select waypoints spread evenly around the circle
        var selectedWaypoints: [CLLocationCoordinate2D] = []
        let targetBearingIncrement = 360.0 / Double(count)

        for i in 0..<count {
            let targetBearing = Double(i) * targetBearingIncrement

            // Find point closest to target bearing
            let best = candidatePoints.min { a, b in
                let bearingA = calculateBearing(from: center, to: a.point)
                let bearingB = calculateBearing(from: center, to: b.point)
                let diffA = abs(angleDifference(bearingA, targetBearing))
                let diffB = abs(angleDifference(bearingB, targetBearing))
                return diffA < diffB
            }

            if let best = best {
                selectedWaypoints.append(best.point)
            }
        }

        print("🗺️ Selected \(selectedWaypoints.count) waypoints on residential streets")
        return selectedWaypoints
    }

    // MARK: - Helper Functions

    private func calculateBearing(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let lat1 = from.latitude * .pi / 180.0
        let lon1 = from.longitude * .pi / 180.0
        let lat2 = to.latitude * .pi / 180.0
        let lon2 = to.longitude * .pi / 180.0

        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        let bearing = atan2(y, x) * 180.0 / .pi

        return (bearing + 360.0).truncatingRemainder(dividingBy: 360.0)
    }

    private func angleDifference(_ angle1: Double, _ angle2: Double) -> Double {
        var diff = angle1 - angle2
        while diff > 180 { diff -= 360 }
        while diff < -180 { diff += 360 }
        return diff
    }
}

// MARK: - Response Models

struct OverpassResponse: Codable {
    let elements: [OverpassElement]
}

struct OverpassElement: Codable {
    let type: String
    let id: Int
    let geometry: [OverpassNode]?
    let tags: [String: String]?
}

struct OverpassNode: Codable {
    let lat: Double
    let lon: Double
}

// MARK: - Errors

enum OverpassError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case noStreetsFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Overpass API URL"
        case .invalidResponse:
            return "Invalid response from Overpass API"
        case .apiError(let statusCode):
            return "Overpass API error (status code: \(statusCode))"
        case .noStreetsFound:
            return "No residential streets found in area"
        }
    }
}
