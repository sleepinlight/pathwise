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
