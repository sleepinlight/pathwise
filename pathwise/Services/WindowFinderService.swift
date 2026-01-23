//
//  WindowFinderService.swift
//  pathwise
//
//  The core "Brain" - Golden Window algorithm
//

import Foundation

class WindowFinderService {
    private let preferences: UserPreferences

    init(preferences: UserPreferences = UserPreferences()) {
        self.preferences = preferences
    }

    // MARK: - Main Algorithm
    func findGoldenWindow(
        freeBlocks: [FreeTimeBlock],
        weatherForecast: [HourlyWeather],
        lookAheadHours: Int = 12
    ) -> GoldenWindow? {
        let now = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: lookAheadHours, to: now)!

        // Step 1: Find all potential windows (free time blocks >= walk duration)
        let potentialWindows = findPotentialWindows(
            freeBlocks: freeBlocks,
            startTime: now,
            endTime: endTime
        )

        guard !potentialWindows.isEmpty else {
            return nil
        }

        // Step 2: Score each window based on weather and daylight
        let scoredWindows = potentialWindows.compactMap { window -> ScoredWindow? in
            guard let weather = findWeatherForTime(window.startTime, forecast: weatherForecast) else {
                return nil
            }

            // Filter out extreme weather
            if isWeatherExtreme(weather) {
                return nil
            }

            let score = calculateWindowScore(time: window.startTime, weather: weather)
            return ScoredWindow(window: window, weather: weather, score: score)
        }

        // Step 3: Select the highest scoring window
        guard let bestWindow = scoredWindows.max(by: { $0.score < $1.score }) else {
            return nil
        }

        let reason = generateReasonSummary(weather: bestWindow.weather, score: bestWindow.score)

        return GoldenWindow(
            startTime: bestWindow.window.startTime,
            endTime: bestWindow.window.endTime,
            score: bestWindow.score,
            weather: bestWindow.weather,
            reasonSummary: reason,
            locationName: nil  // Will be set by ViewModel
        )
    }

    // MARK: - Helper Methods

    private func findPotentialWindows(
        freeBlocks: [FreeTimeBlock],
        startTime: Date,
        endTime: Date
    ) -> [FreeTimeBlock] {
        let minDuration = TimeInterval(preferences.preferredWalkDuration * 60)

        return freeBlocks.filter { block in
            // Block must be within our look-ahead window
            block.startTime >= startTime && block.startTime <= endTime &&
            // Block must be at least as long as preferred walk duration
            block.duration >= minDuration
        }.map { block in
            // Create a window of exactly the preferred duration at the start of each free block
            let windowEnd = Calendar.current.date(
                byAdding: .minute,
                value: preferences.preferredWalkDuration,
                to: block.startTime
            )!
            return FreeTimeBlock(startTime: block.startTime, endTime: windowEnd)
        }
    }

    private func findWeatherForTime(_ time: Date, forecast: [HourlyWeather]) -> HourlyWeather? {
        // Find the weather forecast closest to the given time
        forecast.min(by: { abs($0.time.timeIntervalSince(time)) < abs($1.time.timeIntervalSince(time)) })
    }

    private func isWeatherExtreme(_ weather: HourlyWeather) -> Bool {
        // Extreme weather conditions
        if weather.weatherCondition.isExtreme {
            return true
        }

        // Extreme temperatures
        if preferences.isTemperatureExtreme(weather.temperature) {
            return true
        }

        // High precipitation probability
        if weather.precipitationProbability > 0.5 {
            return true
        }

        return false
    }

    private func calculateWindowScore(time: Date, weather: HourlyWeather) -> Double {
        var score = 0.0

        // Temperature Score (0-40 points)
        let tempScore = calculateTemperatureScore(weather.temperature)
        score += tempScore

        // Daylight Score (0-30 points)
        let daylightScore = calculateDaylightScore(time)
        score += daylightScore

        // Weather Condition Score (0-20 points)
        let conditionScore = calculateConditionScore(weather.weatherCondition)
        score += conditionScore

        // Precipitation Score (0-10 points)
        let precipScore = calculatePrecipitationScore(weather.precipitationProbability)
        score += precipScore

        return score
    }

    private func calculateTemperatureScore(_ temp: Double) -> Double {
        if preferences.isTemperatureIdeal(temp) {
            // Perfect temperature
            return 40.0
        } else if temp >= preferences.idealTemperatureMin - 10 && temp <= preferences.idealTemperatureMax + 10 {
            // Close to ideal (within 10°F)
            let distanceFromIdeal = min(
                abs(temp - preferences.idealTemperatureMin),
                abs(temp - preferences.idealTemperatureMax)
            )
            return 40.0 - (distanceFromIdeal * 2.0)
        } else {
            // Far from ideal
            return 10.0
        }
    }

    private func calculateDaylightScore(_ time: Date) -> Double {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)

        // Peak daylight hours (10 AM - 4 PM): 30 points
        if hour >= 10 && hour < 16 {
            return 30.0
        }
        // Morning/Evening (8-10 AM, 4-6 PM): 20 points
        else if (hour >= 8 && hour < 10) || (hour >= 16 && hour < 18) {
            return 20.0
        }
        // Early morning/Late evening (6-8 AM, 6-8 PM): 10 points
        else if (hour >= 6 && hour < 8) || (hour >= 18 && hour < 20) {
            return 10.0
        }
        // Dark hours: 5 points
        else {
            return 5.0
        }
    }

    private func calculateConditionScore(_ condition: WeatherCondition) -> Double {
        switch condition {
        case .clear:
            return 20.0
        case .partlyCloudy:
            return 18.0
        case .cloudy:
            return 15.0
        case .fog:
            return 10.0
        case .rain, .snow, .thunderstorm:
            return 0.0
        }
    }

    private func calculatePrecipitationScore(_ probability: Double) -> Double {
        // Inverse relationship: lower probability = higher score
        return (1.0 - probability) * 10.0
    }

    private func generateReasonSummary(weather: HourlyWeather, score: Double) -> String {
        let temp = Int(weather.temperature)
        let condition = weather.weatherCondition

        if score >= 80 {
            return "Perfect conditions—\(temp)°F and \(condition.rawValue)"
        } else if score >= 60 {
            return "Great for a walk—\(temp)°F"
        } else {
            return "Best available window—\(temp)°F"
        }
    }

    // MARK: - Supporting Types

    private struct ScoredWindow {
        let window: FreeTimeBlock
        let weather: HourlyWeather
        let score: Double
    }
}
