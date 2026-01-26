//
//  WeatherService.swift
//  pathwise
//
//  Weather data fetching using Apple's WeatherKit
//

import Foundation
import WeatherKit
import CoreLocation
import Combine

class WeatherService: ObservableObject {
    private let weatherService = WeatherKit.WeatherService.shared

    @Published var currentForecast: [HourlyWeather] = []
    @Published var weatherAlerts: [WeatherAlert] = []
    @Published var isLoading = false
    @Published var error: WeatherError?

    // MARK: - Fetch Weather
    func fetchWeather(for location: CLLocation) async {
        await MainActor.run {
            isLoading = true
            error = nil
        }

        print("🌤 WeatherService: Fetching weather for location: \(location.coordinate.latitude), \(location.coordinate.longitude)")

        do {
            let weather = try await weatherService.weather(for: location)
            print("🌤 WeatherService: Successfully fetched weather data")

            // Convert WeatherKit hourly forecast to our model
            let hourlyForecasts = weather.hourlyForecast.forecast.prefix(24).map { hour in
                convertToHourlyWeather(hour)
            }

            // Convert WeatherKit alerts to our model
            let alerts = weather.weatherAlerts?.compactMap { alert in
                convertToWeatherAlert(alert)
            } ?? []

            await MainActor.run {
                self.currentForecast = hourlyForecasts
                self.weatherAlerts = alerts
                self.isLoading = false
            }
        } catch {
            print("❌ WeatherService: Error fetching weather - \(error)")
            print("❌ WeatherService: Error type: \(type(of: error))")
            print("❌ WeatherService: Error localized description: \(error.localizedDescription)")

            await MainActor.run {
                // Provide more detailed error messaging
                let errorMessage: String
                if let weatherError = error as? WeatherError {
                    errorMessage = weatherError.localizedDescription
                } else {
                    errorMessage = "WeatherKit error: \(error.localizedDescription). Ensure WeatherKit is enabled in your Apple Developer account and location permission is granted."
                }
                self.error = .fetchFailed(errorMessage)
                self.isLoading = false
            }
        }
    }

    // MARK: - Mock Data (for development/testing)
    func fetchMockWeather() {
        let now = Date()
        var mockForecasts: [HourlyWeather] = []

        for hour in 0..<24 {
            let time = Calendar.current.date(byAdding: .hour, value: hour, to: now)!
            let temp = 55.0 + Double.random(in: -10...25) // Vary temperature
            let precip = Double.random(in: 0...0.3)
            let uv = Int.random(in: 1...8)

            let condition: WeatherCondition
            if precip > 0.6 {
                condition = .rain
            } else if hour >= 6 && hour <= 18 {
                condition = .clear
            } else {
                condition = .partlyCloudy
            }

            mockForecasts.append(HourlyWeather(
                time: time,
                temperature: temp,
                precipitationProbability: precip,
                uvIndex: uv,
                weatherCondition: condition
            ))
        }

        currentForecast = mockForecasts
    }

    // MARK: - Conversion Helper
    private func convertToHourlyWeather(_ weatherKitHour: HourWeather) -> HourlyWeather {
        let condition = mapWeatherKitCondition(weatherKitHour.condition)

        return HourlyWeather(
            time: weatherKitHour.date,
            temperature: weatherKitHour.temperature.value, // Convert to Fahrenheit if needed
            precipitationProbability: weatherKitHour.precipitationChance,
            uvIndex: weatherKitHour.uvIndex.value,
            weatherCondition: condition
        )
    }

    private func mapWeatherKitCondition(_ condition: WeatherKit.WeatherCondition) -> WeatherCondition {
        // Map WeatherKit.WeatherCondition to our custom WeatherCondition enum
        switch condition {
        case .clear, .mostlyClear:
            return .clear
        case .partlyCloudy, .mostlyCloudy:
            return .partlyCloudy
        case .cloudy:
            return .cloudy
        case .rain, .drizzle, .heavyRain, .freezingRain, .sunShowers:
            return .rain
        case .snow, .sleet, .flurries, .blizzard, .blowingSnow, .freezingDrizzle, .wintryMix:
            return .snow
        case .strongStorms, .tropicalStorm, .hurricane, .isolatedThunderstorms, .scatteredThunderstorms, .thunderstorms:
            return .thunderstorm
        case .foggy, .smoky, .haze:
            return .fog
        default:
            return .partlyCloudy
        }
    }

    // MARK: - Weather Alert Conversion
    private func convertToWeatherAlert(_ weatherKitAlert: WeatherKit.WeatherAlert) -> WeatherAlert? {
        // Map WeatherKit severity to our severity
        let severity: WeatherAlertSeverity
        switch weatherKitAlert.severity {
        case .extreme:
            severity = .extreme
        case .severe:
            severity = .severe
        case .moderate:
            severity = .moderate
        case .minor, .unknown:
            severity = .minor
        @unknown default:
            severity = .minor
        }

        // Get event name and headline from WeatherKit alert
        // WeatherKit provides: source (issuing authority), summary (headline)
        let event = weatherKitAlert.source // e.g., "National Weather Service"
        let headline = weatherKitAlert.summary

        // NOTE: WeatherKit's Swift API doesn't expose effectiveTime/expireTime properties
        // directly on WeatherAlert like the REST API does. As a workaround, we use the
        // current time as the start and add 24 hours for a reasonable end time.
        // This ensures alerts are considered "active" when they appear in the API response.
        let now = Date()
        let startTime = now
        let endTime = Calendar.current.date(byAdding: .hour, value: 24, to: now) ?? now

        return WeatherAlert(
            event: event,
            headline: headline,
            severity: severity,
            startTime: startTime,
            endTime: endTime
        )
    }
}

// MARK: - Error Types
enum WeatherError: LocalizedError {
    case fetchFailed(String)
    case locationUnavailable

    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Weather fetch failed: \(message)"
        case .locationUnavailable:
            return "Location unavailable"
        }
    }
}
