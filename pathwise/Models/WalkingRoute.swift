//
//  WalkingRoute.swift
//  pathwise
//
//  Models for walking route generation
//

import Foundation
import CoreLocation
import MapKit

// MARK: - Walking Route

struct WalkingRoute: Identifiable {
    let id = UUID()
    let coordinates: [CLLocationCoordinate2D]
    let distance: Double // in miles
    let duration: Double // in minutes
    let polyline: String
    let steps: [RouteStep]?

    var distanceFormatted: String {
        String(format: "%.1f mi", distance)
    }

    var durationFormatted: String {
        let mins = Int(duration)
        if mins < 60 {
            return "\(mins) min"
        } else {
            let hours = mins / 60
            let remainingMins = mins % 60
            return "\(hours)h \(remainingMins)m"
        }
    }
}

// MARK: - Route Step (for turn-by-turn)

struct RouteStep {
    let instruction: String
    let distance: Double // in miles
    let duration: Double // in seconds
}

// MARK: - Mapbox API Response Models

struct MapboxDirectionsResponse: Codable {
    let routes: [MapboxRoute]
    let code: String
}

struct MapboxRoute: Codable {
    let geometry: String
    let distance: Double // in meters
    let duration: Double // in seconds
    let legs: [MapboxLeg]?
}

struct MapboxLeg: Codable {
    let steps: [MapboxStep]?
}

struct MapboxStep: Codable {
    let maneuver: MapboxManeuver?
    let distance: Double // in meters
    let duration: Double // in seconds
}

struct MapboxManeuver: Codable {
    let instruction: String?
}

// MARK: - Route Distance Options

enum RouteDistance: Double, CaseIterable, Identifiable {
    case oneMile = 1.0
    case twoMiles = 2.0
    case threeMiles = 3.0
    case fiveMiles = 5.0

    var id: Double { rawValue }

    var displayText: String {
        if rawValue == 1.0 {
            return "1 mi"
        } else {
            return "\(Int(rawValue)) mi"
        }
    }
}
