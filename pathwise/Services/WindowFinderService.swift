//
//  WindowFinderService.swift
//  pathwise
//
//  The core "Brain" - Golden Window algorithm
//

import Foundation

// MARK: - Window Result Types
enum WindowQuality {
    case ideal      // Score >= 70
    case good       // Score >= 50
    case acceptable // Score >= 30
    case fallback   // Any window, even if not great
}

struct SplitWalkSuggestion {
    let windows: [GoldenWindow]  // The windows to combine
    let totalDuration: Int       // Combined duration in minutes
    let combinedScore: Double    // Average score

    var description: String {
        let times = windows.map { $0.timeString }.joined(separator: " and ")
        return "Split your walk: \(windows[0].durationInMinutes) min at \(times)"
    }
}

struct WindowResult {
    let goldenWindows: [GoldenWindow]  // All ideal/good windows
    let fallbackWindow: GoldenWindow?  // Best available if no golden windows
    let splitWalkSuggestion: SplitWalkSuggestion?  // Suggestion to split walk into multiple sessions
    let noWindowReason: NoWindowReason? // Why there are no windows

    var hasGoldenWindows: Bool {
        !goldenWindows.isEmpty
    }

    var hasFallback: Bool {
        fallbackWindow != nil
    }

    var hasSplitSuggestion: Bool {
        splitWalkSuggestion != nil
    }
}

enum NoWindowReason: String {
    case noFreeTime = "Your calendar is fully booked"
    case unsafeWeather = "Weather conditions are unsafe"
    case poorWeather = "Weather conditions aren't ideal"
    case scheduleTooTight = "No time slots long enough for a walk"
    case noWeatherData = "Weather data unavailable"

    var severity: WeatherSeverity {
        switch self {
        case .unsafeWeather:
            return .unsafe
        case .poorWeather:
            return .poor
        case .noFreeTime, .scheduleTooTight, .noWeatherData:
            return .none
        }
    }
}

enum WeatherSeverity {
    case none      // Not weather-related
    case poor      // Not ideal but walkable (light rain, fog, mild conditions)
    case unsafe    // Dangerous (thunderstorms, heavy rain, extreme temps)
}

class WindowFinderService {
    private let preferences: UserPreferences

    init(preferences: UserPreferences = UserPreferences()) {
        self.preferences = preferences
    }

    // MARK: - Main Algorithm (New)
    func findAllWindows(
        freeBlocks: [FreeTimeBlock],
        weatherForecast: [HourlyWeather],
        lookAheadHours: Int = 12
    ) -> WindowResult {
        let now = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: lookAheadHours, to: now)!

        // Step 1: Find all potential windows
        let potentialWindows = findPotentialWindows(
            freeBlocks: freeBlocks,
            startTime: now,
            endTime: endTime
        )

        // Check if there are no free blocks at all
        if potentialWindows.isEmpty {
            let reason: NoWindowReason = freeBlocks.isEmpty ? .noFreeTime : .scheduleTooTight

            // Before giving up, check if we can suggest splitting the walk
            let splitSuggestion = findSplitWalkSuggestion(freeBlocks: freeBlocks, weatherForecast: weatherForecast)

            return WindowResult(
                goldenWindows: [],
                fallbackWindow: nil,
                splitWalkSuggestion: splitSuggestion,
                noWindowReason: reason
            )
        }

        // Step 2: Score all windows and categorize them
        var allScoredWindows: [ScoredWindow] = []
        var poorWeatherWindows: [ScoredWindow] = []
        var extremeWeatherWindows: [ScoredWindow] = []

        for window in potentialWindows {
            guard let weather = findWeatherForTime(window.startTime, forecast: weatherForecast) else {
                continue
            }

            let score = calculateWindowScore(time: window.startTime, weather: weather)
            let scoredWindow = ScoredWindow(window: window, weather: weather, score: score)

            if isWeatherExtreme(weather) {
                extremeWeatherWindows.append(scoredWindow)
            } else if isWeatherPoor(weather) {
                poorWeatherWindows.append(scoredWindow)
            } else {
                allScoredWindows.append(scoredWindow)
            }
        }

        // Step 3: Separate golden windows (score >= 50) from fallback windows
        let goldenWindowThreshold = 50.0
        let goldenScoredWindows = allScoredWindows.filter { $0.score >= goldenWindowThreshold }
        let acceptableScoredWindows = allScoredWindows.filter { $0.score < goldenWindowThreshold }

        // Step 4: Build result
        var goldenWindows: [GoldenWindow] = []
        var fallbackWindow: GoldenWindow?
        var noWindowReason: NoWindowReason?

        // Convert golden windows (sorted by time, not score)
        if !goldenScoredWindows.isEmpty {
            goldenWindows = goldenScoredWindows
                .sorted { $0.window.startTime < $1.window.startTime } // Earliest time first
                .map { createGoldenWindow(from: $0) }
        } else {
            // No golden windows - try to provide a fallback
            if let bestAcceptable = acceptableScoredWindows.max(by: { $0.score < $1.score }) {
                // There's an acceptable (but not ideal) window
                fallbackWindow = createGoldenWindow(from: bestAcceptable, isFallback: true)
            } else if let bestPoor = poorWeatherWindows.max(by: { $0.score < $1.score }) {
                // Only poor weather windows available
                noWindowReason = .poorWeather
                fallbackWindow = createGoldenWindow(from: bestPoor, isFallback: true)
            } else if let leastBad = extremeWeatherWindows.max(by: { $0.score < $1.score }) {
                // Only unsafe weather windows available
                noWindowReason = .unsafeWeather
                fallbackWindow = createGoldenWindow(from: leastBad, isFallback: true)
            } else {
                // No weather data at all
                noWindowReason = .noWeatherData
            }
        }

        // Check for split walk suggestions even if we have no golden windows
        var splitSuggestion: SplitWalkSuggestion?
        if goldenWindows.isEmpty && fallbackWindow == nil {
            splitSuggestion = findSplitWalkSuggestion(freeBlocks: freeBlocks, weatherForecast: weatherForecast)
        }

        return WindowResult(
            goldenWindows: goldenWindows,
            fallbackWindow: fallbackWindow,
            splitWalkSuggestion: splitSuggestion,
            noWindowReason: noWindowReason
        )
    }

    // MARK: - Legacy Method (for backward compatibility)
    func findGoldenWindow(
        freeBlocks: [FreeTimeBlock],
        weatherForecast: [HourlyWeather],
        lookAheadHours: Int = 12
    ) -> GoldenWindow? {
        let result = findAllWindows(
            freeBlocks: freeBlocks,
            weatherForecast: weatherForecast,
            lookAheadHours: lookAheadHours
        )
        return result.goldenWindows.first ?? result.fallbackWindow
    }

    // MARK: - Helper to create GoldenWindow from ScoredWindow
    private func createGoldenWindow(from scored: ScoredWindow, isFallback: Bool = false) -> GoldenWindow {
        let reason = generateReasonSummary(weather: scored.weather, score: scored.score, isFallback: isFallback)
        return GoldenWindow(
            startTime: scored.window.startTime,
            endTime: scored.window.endTime,
            score: scored.score,
            weather: scored.weather,
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
        let calendar = Calendar.current

        return freeBlocks.filter { block in
            let blockComponents = calendar.dateComponents([.hour, .minute], from: block.startTime)
            let startComponents = calendar.dateComponents([.hour, .minute], from: preferences.preferredWalkStartTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: preferences.preferredWalkEndTime)

            let blockMinutes = (blockComponents.hour ?? 0) * 60 + (blockComponents.minute ?? 0)
            let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
            let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)

            // Block must be within our look-ahead window
            return block.startTime >= startTime && block.startTime <= endTime &&
            // Block must be at least as long as preferred walk duration
            block.duration >= minDuration &&
            // Block must be within preferred walking time
            blockMinutes >= startMinutes && blockMinutes < endMinutes
        }.map { block in
            // Create a window of exactly the preferred duration at the start of each free block
            let windowEnd = calendar.date(
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
        // Truly dangerous conditions
        if weather.weatherCondition == .thunderstorm {
            return true
        }

        // Extreme temperatures
        if preferences.isTemperatureExtreme(weather.temperature) {
            return true
        }

        // Very high precipitation probability (heavy rain)
        if weather.precipitationProbability > 0.7 {
            return true
        }

        return false
    }

    private func isWeatherPoor(_ weather: HourlyWeather) -> Bool {
        // Not ideal but walkable conditions
        if weather.weatherCondition == .rain || weather.weatherCondition == .snow {
            return true
        }

        if weather.weatherCondition == .fog {
            return true
        }

        // Moderate precipitation probability
        if weather.precipitationProbability > 0.4 && weather.precipitationProbability <= 0.7 {
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

    private func generateReasonSummary(weather: HourlyWeather, score: Double, isFallback: Bool = false) -> String {
        let temp = Int(weather.temperature)
        let condition = weather.weatherCondition

        if isFallback {
            // Explain why it's not ideal
            var reasons: [String] = []

            if !preferences.isTemperatureIdeal(weather.temperature) {
                if weather.temperature < preferences.idealTemperatureMin {
                    reasons.append("a bit chilly at \(temp)°F")
                } else {
                    reasons.append("a bit warm at \(temp)°F")
                }
            }

            if weather.precipitationProbability > 0.3 {
                reasons.append("\(Int(weather.precipitationProbability * 100))% chance of rain")
            }

            if condition != .clear && condition != .partlyCloudy {
                reasons.append(condition.displayName.lowercased())
            }

            if reasons.isEmpty {
                return "Not ideal, but best option—\(temp)°F"
            } else {
                return "Best available—" + reasons.joined(separator: ", ")
            }
        }

        // Standard golden window descriptions
        if score >= 80 {
            return "Perfect conditions—\(temp)°F and \(condition.displayName.lowercased())"
        } else if score >= 60 {
            return "Great for a walk—\(temp)°F"
        } else {
            return "Good window—\(temp)°F"
        }
    }

    // MARK: - Split Walk Suggestion
    private func findSplitWalkSuggestion(
        freeBlocks: [FreeTimeBlock],
        weatherForecast: [HourlyWeather]
    ) -> SplitWalkSuggestion? {
        let now = Date()
        let calendar = Calendar.current
        let endTime = calendar.date(byAdding: .hour, value: 12, to: now)!
        let targetDuration = TimeInterval(preferences.preferredWalkDuration * 60)

        // Find all available blocks (even if shorter than target)
        let availableBlocks = freeBlocks.filter { block in
            let blockComponents = calendar.dateComponents([.hour, .minute], from: block.startTime)
            let startComponents = calendar.dateComponents([.hour, .minute], from: preferences.preferredWalkStartTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: preferences.preferredWalkEndTime)

            let blockMinutes = (blockComponents.hour ?? 0) * 60 + (blockComponents.minute ?? 0)
            let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
            let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)

            return block.startTime >= now && block.startTime <= endTime &&
            block.duration >= 600 && // At least 10 minutes
            blockMinutes >= startMinutes && blockMinutes < endMinutes
        }

        guard availableBlocks.count >= 2 else {
            return nil // Need at least 2 blocks to split
        }

        // Try to find 2 blocks that combine to meet or exceed target duration
        for i in 0..<availableBlocks.count {
            for j in (i+1)..<availableBlocks.count {
                let block1 = availableBlocks[i]
                let block2 = availableBlocks[j]
                let combinedDuration = block1.duration + block2.duration

                // Check if combined duration is at least 80% of target
                if combinedDuration >= targetDuration * 0.8 {
                    // Get weather for both blocks
                    guard let weather1 = findWeatherForTime(block1.startTime, forecast: weatherForecast),
                          let weather2 = findWeatherForTime(block2.startTime, forecast: weatherForecast) else {
                        continue
                    }

                    // Skip if either has extreme weather
                    if isWeatherExtreme(weather1) || isWeatherExtreme(weather2) {
                        continue
                    }

                    // Calculate scores
                    let score1 = calculateWindowScore(time: block1.startTime, weather: weather1)
                    let score2 = calculateWindowScore(time: block2.startTime, weather: weather2)
                    let avgScore = (score1 + score2) / 2.0

                    // Create windows for the suggestion
                    let window1 = GoldenWindow(
                        startTime: block1.startTime,
                        endTime: block1.endTime,
                        score: score1,
                        weather: weather1,
                        reasonSummary: generateReasonSummary(weather: weather1, score: score1),
                        locationName: nil
                    )

                    let window2 = GoldenWindow(
                        startTime: block2.startTime,
                        endTime: block2.endTime,
                        score: score2,
                        weather: weather2,
                        reasonSummary: generateReasonSummary(weather: weather2, score: score2),
                        locationName: nil
                    )

                    return SplitWalkSuggestion(
                        windows: [window1, window2],
                        totalDuration: Int(combinedDuration / 60),
                        combinedScore: avgScore
                    )
                }
            }
        }

        return nil
    }

    // MARK: - Supporting Types

    private struct ScoredWindow {
        let window: FreeTimeBlock
        let weather: HourlyWeather
        let score: Double
    }
}
