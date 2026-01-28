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
    let isInGoldenWindow: Bool  // Is the current time within a golden window?
    let activeWeatherAlerts: [WeatherAlert]  // Active severe weather alerts
    let calendarWasConsidered: Bool  // Whether calendar was factored into the result

    var hasGoldenWindows: Bool {
        !goldenWindows.isEmpty
    }

    var hasFallback: Bool {
        fallbackWindow != nil
    }

    var hasSplitSuggestion: Bool {
        splitWalkSuggestion != nil
    }

    var hasSevereWeatherAlerts: Bool {
        !activeWeatherAlerts.isEmpty
    }

    var isCalendarBlocking: Bool {
        // Calendar is blocking if there's no window AND the reason is calendar-related
        guard !hasGoldenWindows && !hasFallback else { return false }
        guard let reason = noWindowReason else { return false }
        return reason == .noFreeTime || reason == .scheduleTooTight
    }
}

enum WeatherSeverity {
    case none      // Not weather-related
    case poor      // Not ideal but walkable (light rain, fog, mild conditions)
    case unsafe    // Dangerous (thunderstorms, heavy rain, extreme temps)
}

extension NoWindowReason {
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

class WindowFinderService {
    private let preferences: UserPreferences

    init(preferences: UserPreferences = UserPreferences()) {
        self.preferences = preferences
    }

    // MARK: - Main Algorithm (New)
    func findAllWindows(
        freeBlocks: [FreeTimeBlock],
        weatherForecast: [HourlyWeather],
        activeWeatherAlerts: [WeatherAlert] = [],
        ignoreCalendar: Bool = false,
        lookAheadHours: Int = 12
    ) -> WindowResult {
        let now = Date()
        let endTime = Calendar.current.date(byAdding: .hour, value: lookAheadHours, to: now)!

        // Step 1: Find all potential windows
        // If ignoring calendar, create synthetic free blocks for the entire period
        let blocksToConsider: [FreeTimeBlock]
        if ignoreCalendar {
            // Create hourly blocks for the entire look-ahead period
            var syntheticBlocks: [FreeTimeBlock] = []
            var currentTime = now
            while currentTime < endTime {
                let blockEnd = Calendar.current.date(byAdding: .hour, value: 1, to: currentTime)!
                syntheticBlocks.append(FreeTimeBlock(startTime: currentTime, endTime: blockEnd))
                currentTime = blockEnd
            }
            blocksToConsider = syntheticBlocks
        } else {
            blocksToConsider = freeBlocks
        }

        let potentialWindows = findPotentialWindows(
            freeBlocks: blocksToConsider,
            startTime: now,
            endTime: endTime
        )

        // Check if there are no free blocks at all (calendar-based issue)
        if potentialWindows.isEmpty {
            // IMPORTANT: Before blaming the calendar, check if weather is the real issue
            // If ALL free blocks have extreme weather, we should report weather as the reason
            let allBlocksHaveExtremeWeather = !blocksToConsider.isEmpty && blocksToConsider.allSatisfy { block in
                guard let weather = findWeatherForTime(block.startTime, forecast: weatherForecast) else {
                    return false
                }
                return isWeatherExtreme(weather)
            }

            let allBlocksHavePoorWeather = !blocksToConsider.isEmpty && blocksToConsider.allSatisfy { block in
                guard let weather = findWeatherForTime(block.startTime, forecast: weatherForecast) else {
                    return false
                }
                return isWeatherExtreme(weather) || isWeatherPoor(weather)
            }

            // Determine the actual reason
            let reason: NoWindowReason
            if allBlocksHaveExtremeWeather {
                reason = .unsafeWeather
            } else if allBlocksHavePoorWeather {
                reason = .poorWeather
            } else if freeBlocks.isEmpty && !ignoreCalendar {
                reason = .noFreeTime
            } else {
                reason = .scheduleTooTight
            }

            // Before giving up, check if we can suggest splitting the walk
            let splitSuggestion = findSplitWalkSuggestion(freeBlocks: blocksToConsider, weatherForecast: weatherForecast)

            return WindowResult(
                goldenWindows: [],
                fallbackWindow: nil,
                splitWalkSuggestion: splitSuggestion,
                noWindowReason: reason,
                isInGoldenWindow: false,
                activeWeatherAlerts: activeWeatherAlerts.filter { $0.isActive },
                calendarWasConsidered: !ignoreCalendar
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

        // Convert golden windows - prioritize by quality, consolidate consecutive windows, limit to top 3
        if !goldenScoredWindows.isEmpty {
            // Sort by time first to find consecutive windows
            let sortedByTime = goldenScoredWindows.sorted { $0.window.startTime < $1.window.startTime }

            // Consolidate consecutive hourly windows into ranges
            let consolidatedWindows = consolidateConsecutiveWindows(sortedByTime)

            // Now pick top 3 by score
            goldenWindows = consolidatedWindows
                .sorted { $0.score > $1.score } // Highest score first (quality over time)
                .prefix(3) // Limit to top 3 highest quality windows
                .sorted { $0.window.startTime < $1.window.startTime } // Then sort by time for display
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

        // Check if current time is within any golden window
        // Account for the buffer time - if we're within 3 minutes before the window starts, we're "in" it
        let bufferMinutes: TimeInterval = 3 * 60
        let isInGoldenWindow = goldenWindows.contains { window in
            let windowStartWithBuffer = window.startTime.addingTimeInterval(-bufferMinutes)
            return now >= windowStartWithBuffer && now <= window.endTime
        }

        return WindowResult(
            goldenWindows: goldenWindows,
            fallbackWindow: fallbackWindow,
            splitWalkSuggestion: splitSuggestion,
            noWindowReason: noWindowReason,
            isInGoldenWindow: isInGoldenWindow,
            activeWeatherAlerts: activeWeatherAlerts.filter { $0.isActive },
            calendarWasConsidered: !ignoreCalendar
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

    // MARK: - Helper to consolidate consecutive windows
    private func consolidateConsecutiveWindows(_ windows: [ScoredWindow]) -> [ScoredWindow] {
        guard !windows.isEmpty else { return [] }

        var consolidated: [ScoredWindow] = []
        var currentGroup: [ScoredWindow] = [windows[0]]

        for i in 1..<windows.count {
            let previous = windows[i - 1]
            let current = windows[i]

            // Check if windows are consecutive (within 90 minutes of each other)
            let timeDiff = current.window.startTime.timeIntervalSince(previous.window.startTime)
            let areConsecutive = timeDiff <= 90 * 60 // 90 minutes

            // Check if weather/score are similar (within 5 degrees and 10 score points)
            let tempDiff = abs(current.weather.temperature - previous.weather.temperature)
            let scoreDiff = abs(current.score - previous.score)
            let areSimilar = tempDiff <= 5.0 && scoreDiff <= 10.0

            if areConsecutive && areSimilar {
                // Add to current group
                currentGroup.append(current)
            } else {
                // Finalize current group and start new one
                if currentGroup.count >= 2 {
                    // Consolidate group into a single window (range)
                    consolidated.append(consolidateGroup(currentGroup))
                } else {
                    // Keep single windows as-is
                    consolidated.append(contentsOf: currentGroup)
                }
                currentGroup = [current]
            }
        }

        // Handle last group
        if currentGroup.count >= 2 {
            consolidated.append(consolidateGroup(currentGroup))
        } else {
            consolidated.append(contentsOf: currentGroup)
        }

        return consolidated
    }

    private func consolidateGroup(_ group: [ScoredWindow]) -> ScoredWindow {
        // Use first window's start time and last window's end time to create a range
        let startTime = group.first!.window.startTime
        let endTime = group.last!.window.endTime

        // Use the best score and weather from the group
        let bestWindow = group.max(by: { $0.score < $1.score })!

        return ScoredWindow(
            window: FreeTimeBlock(startTime: startTime, endTime: endTime),
            weather: bestWindow.weather,
            score: bestWindow.score
        )
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
        let bufferMinutes = 3 // Buffer time before and after walk
        let totalRequiredDuration = TimeInterval((preferences.preferredWalkDuration + bufferMinutes * 2) * 60)
        let calendar = Calendar.current

        print("🔍 WindowFinder: Filtering \(freeBlocks.count) free blocks")
        print("   Required duration: \(totalRequiredDuration / 60) minutes")
        print("   Look-ahead window: \(startTime) to \(endTime)")

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        print("   Preferred walk time: \(formatter.string(from: preferences.preferredWalkStartTime)) to \(formatter.string(from: preferences.preferredWalkEndTime))")

        let filtered = freeBlocks.filter { block in
            let blockComponents = calendar.dateComponents([.hour, .minute], from: block.startTime)
            let startComponents = calendar.dateComponents([.hour, .minute], from: preferences.preferredWalkStartTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: preferences.preferredWalkEndTime)

            let blockMinutes = (blockComponents.hour ?? 0) * 60 + (blockComponents.minute ?? 0)
            let startMinutes = (startComponents.hour ?? 0) * 60 + (startComponents.minute ?? 0)
            let endMinutes = (endComponents.hour ?? 0) * 60 + (endComponents.minute ?? 0)

            // Allow blocks that start within 60 seconds before the look-ahead window
            // (to account for timing differences between when calendar service and window finder run)
            let blockStartWithTolerance = block.startTime.addingTimeInterval(60)
            let withinLookAhead = blockStartWithTolerance >= startTime && block.startTime <= endTime
            let longEnough = block.duration >= totalRequiredDuration
            let inPreferredTime = blockMinutes >= startMinutes && blockMinutes < endMinutes

            print("   Block \(block.timeRangeString) (\(block.durationInMinutes) min):")
            print("     - Block start: \(block.startTime.timeIntervalSince1970)")
            print("     - Window start: \(startTime.timeIntervalSince1970)")
            print("     - Window end: \(endTime.timeIntervalSince1970)")
            print("     - Within look-ahead: \(withinLookAhead)")
            print("     - Long enough: \(longEnough) (need \(Int(totalRequiredDuration / 60)) min)")
            print("     - In preferred time: \(inPreferredTime) (block: \(blockMinutes) min, range: \(startMinutes)-\(endMinutes) min)")

            // Block must be within our look-ahead window
            return withinLookAhead &&
            // Block must be at least as long as walk duration + buffer on both sides
            longEnough &&
            // Block must be within preferred walking time
            inPreferredTime
        }

        print("🔍 WindowFinder: \(filtered.count) blocks passed filters")

        return filtered.map { block in
            // Create a window with buffer time before and after
            // Start the walk after the buffer
            let windowStart = calendar.date(
                byAdding: .minute,
                value: bufferMinutes,
                to: block.startTime
            )!
            let windowEnd = calendar.date(
                byAdding: .minute,
                value: preferences.preferredWalkDuration,
                to: windowStart
            )!
            return FreeTimeBlock(startTime: windowStart, endTime: windowEnd)
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
                    let tempDescription = getTemperatureDescription(temp, isCold: true)
                    reasons.append("\(tempDescription) at \(temp)°F")
                } else {
                    let tempDescription = getTemperatureDescription(temp, isCold: false)
                    reasons.append("\(tempDescription) at \(temp)°F")
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

    /// Generates contextually appropriate temperature descriptions
    private func getTemperatureDescription(_ temp: Int, isCold: Bool) -> String {
        if isCold {
            // Cold temperature descriptions
            switch temp {
            case ..<0:
                return "dangerously cold"
            case 0..<20:
                return "quite cold"
            case 20..<35:
                return "chilly"
            case 35..<50:
                return "a bit chilly"
            default:
                return "cool"
            }
        } else {
            // Hot temperature descriptions
            switch temp {
            case 95...:
                return "dangerously hot"
            case 85..<95:
                return "quite hot"
            case 78..<85:
                return "a bit warm"
            case 70..<78:
                return "slightly warm"
            default:
                return "warm"
            }
        }
    }

    // MARK: - Supporting Types

    private struct ScoredWindow {
        let window: FreeTimeBlock
        let weather: HourlyWeather
        let score: Double
    }
}
