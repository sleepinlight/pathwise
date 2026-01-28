//
//  StadiaMapsConfig.swift
//  pathwise
//
//  Configuration for Stadia Maps API
//

import Foundation

struct StadiaMapsConfig {
    // TODO: Replace with your Stadia Maps API key
    // Get one at: https://client.stadiamaps.com/signup/
    static let apiKey = "dbfc8f17-20c7-4013-9c99-2d6a07c397d6"

    static let routingAPIBaseURL = "https://api.stadiamaps.com/route/v1"

    // Routing profile for pedestrian walking
    static let profile = "pedestrian"
}
