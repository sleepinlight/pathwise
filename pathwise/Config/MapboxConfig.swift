//
//  MapboxConfig.swift
//  pathwise
//
//  Configuration for Mapbox API
//

import Foundation

struct MapboxConfig {
    // API token is stored in Secrets.swift (gitignored)
    static let accessToken = Secrets.mapboxAccessToken

    static let directionsAPIBaseURL = "https://api.mapbox.com/directions/v5"
    static let profile = "mapbox/walking"
}
