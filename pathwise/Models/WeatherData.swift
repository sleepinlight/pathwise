//
//  WeatherData.swift
//  pathwise
//
//  Weather data models
//

import Foundation

struct HourlyWeather: Identifiable, Codable {
    let id = UUID()
    let time: Date
    let temperature: Double // Fahrenheit
    let precipitationProbability: Double // 0.0 to 1.0
    let uvIndex: Int
    let weatherCondition: WeatherCondition

    enum CodingKeys: String, CodingKey {
        case time, temperature, precipitationProbability, uvIndex, weatherCondition
    }
}

enum WeatherCondition: String, Codable {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case snow
    case thunderstorm
    case fog

    var displayName: String {
        switch self {
        case .clear:
            return "Clear"
        case .partlyCloudy:
            return "Partly Cloudy"
        case .cloudy:
            return "Cloudy"
        case .rain:
            return "Rain"
        case .snow:
            return "Snow"
        case .thunderstorm:
            return "Thunderstorm"
        case .fog:
            return "Fog"
        }
    }

    var sfSymbol: String {
        switch self {
        case .clear:
            return "sun.max.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .cloudy:
            return "cloud.fill"
        case .rain:
            return "cloud.rain.fill"
        case .snow:
            return "cloud.snow.fill"
        case .thunderstorm:
            return "cloud.bolt.fill"
        case .fog:
            return "cloud.fog.fill"
        }
    }

    var isExtreme: Bool {
        switch self {
        case .rain, .snow, .thunderstorm:
            return true
        default:
            return false
        }
    }
}

struct DailyWeatherForecast: Codable {
    let date: Date
    let hourlyForecasts: [HourlyWeather]
}

// MARK: - Severe Weather Alerts

enum WeatherAlertSeverity: String, Codable {
    case extreme = "Extreme"
    case severe = "Severe"
    case moderate = "Moderate"
    case minor = "Minor"
}

struct WeatherAlert: Identifiable, Codable {
    let id = UUID()
    let event: String // e.g., "Severe Thunderstorm Warning", "Winter Storm Warning"
    let headline: String // Brief description
    let severity: WeatherAlertSeverity
    let startTime: Date
    let endTime: Date

    enum CodingKeys: String, CodingKey {
        case event, headline, severity, startTime, endTime
    }

    var iconName: String {
        switch severity {
        case .extreme:
            return "exclamationmark.triangle.fill"
        case .severe:
            return "exclamationmark.octagon.fill"
        case .moderate:
            return "exclamationmark.circle.fill"
        case .minor:
            return "info.circle.fill"
        }
    }

    var color: String {
        switch severity {
        case .extreme:
            return "red"
        case .severe:
            return "orange"
        case .moderate:
            return "yellow"
        case .minor:
            return "blue"
        }
    }

    var isActive: Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }
}
