//
//  StadiaMapsConfig.swift
//  pathwise
//
//  Configuration for Stadia Maps API
//

import Foundation

struct StadiaMapsConfig {
    // API key is stored in Secrets.swift (gitignored)
    static let apiKey = Secrets.stadiaMapsAPIKey

    static let routingAPIBaseURL = "https://api.stadiamaps.com/route/v1"

    // Routing profile for pedestrian walking
    static let profile = "pedestrian"
}
