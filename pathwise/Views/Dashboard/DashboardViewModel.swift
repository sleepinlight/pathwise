//
//  DashboardViewModel.swift
//  pathwise
//
//  ViewModel for the main dashboard
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    // Services
    private let weatherService = WeatherService()
    private let calendarService = CalendarService()
    private let healthService = HealthService()
    private let locationService = LocationService()
    private let windowFinder = WindowFinderService()

    // Published Properties
    @Published var goldenWindows: [GoldenWindow] = []
    @Published var fallbackWindow: GoldenWindow?
    @Published var splitWalkSuggestion: SplitWalkSuggestion?
    @Published var noWindowReason: NoWindowReason?
    @Published var todaySteps: Int = 0
    @Published var todayDistance: Double = 0.0
    @Published var todayMinutes: Int = 0
    @Published var weeklyActivities: [DailyActivity] = []
    @Published var preferences = UserPreferences()
    @Published var isLoading = false

    // Legacy computed property for backward compatibility
    var goldenWindow: GoldenWindow? {
        goldenWindows.first ?? fallbackWindow
    }

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning!"
        case 12..<17:
            return "Good afternoon!"
        default:
            return "Good evening!"
        }
    }

    // MARK: - Initialization
    func initialize() async {
        isLoading = true

        // Load preferences from UserDefaults
        loadPreferences()

        // For Phase 1, we'll use mock data for easier development
        // In production, you'd request permissions and fetch real data
        await loadMockData()

        // Calculate the Golden Window
        calculateGoldenWindow()

        isLoading = false
    }

    func refresh() async {
        // Reload preferences in case they changed in settings
        loadPreferences()

        await loadMockData()
        calculateGoldenWindow()
    }

    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: "userPreferences"),
           let savedPreferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.preferences = savedPreferences
        }
    }

    // MARK: - Real Data Loading (commented out for Phase 1)
    /*
    private func loadRealData() async {
        // Request permissions
        async let calendarAccess = calendarService.requestCalendarAccess()
        async let healthAccess = healthService.requestHealthAccess()

        let (hasCalendar, hasHealth) = await (calendarAccess, healthAccess)

        // Fetch data concurrently
        async let calendar = calendarService.fetchTodayEvents()
        async let weather = weatherService.fetchWeather(for: userLocation)
        async let todayActivity = healthService.fetchTodayActivity()
        async let weeklyActivity = healthService.fetchWeeklyActivity()

        await (calendar, weather, todayActivity, weeklyActivity)

        // Update published properties
        self.todaySteps = healthService.todaySteps
        self.todayDistance = healthService.todayDistance
        self.todayMinutes = healthService.todayMinutesMoved
        self.weeklyActivities = healthService.weeklyActivities
    }
    */

    // MARK: - Mock Data Loading
    private func loadMockData() async {
        // Use mock data for development
        weatherService.fetchMockWeather()
        calendarService.useMockCalendar()
        healthService.useMockHealthData(stepGoal: preferences.dailyStepGoal)
        locationService.useMockLocation()

        // Small delay to simulate network call
        try? await Task.sleep(nanoseconds: 500_000_000)

        // Update from services
        self.todaySteps = healthService.todaySteps
        self.todayDistance = healthService.todayDistance
        self.todayMinutes = healthService.todayMinutesMoved
        self.weeklyActivities = healthService.weeklyActivities
    }

    // MARK: - Golden Window Calculation
    private func calculateGoldenWindow() {
        // Check if dev mode is enabled with a specific scenario
        let devSettings = DeveloperSettings.shared
        let result: WindowResult

        if devSettings.isEnabled && devSettings.currentScenario != .normal {
            result = generateDevScenarioResult(scenario: devSettings.currentScenario)
        } else {
            result = windowFinder.findAllWindows(
                freeBlocks: calendarService.freeBlocks,
                weatherForecast: weatherService.currentForecast,
                lookAheadHours: 12
            )
        }

        // Add location name to all windows
        self.goldenWindows = result.goldenWindows.map { window in
            GoldenWindow(
                startTime: window.startTime,
                endTime: window.endTime,
                score: window.score,
                weather: window.weather,
                reasonSummary: window.reasonSummary,
                locationName: locationService.locationName
            )
        }

        // Add location to fallback window if it exists
        if let fallback = result.fallbackWindow {
            self.fallbackWindow = GoldenWindow(
                startTime: fallback.startTime,
                endTime: fallback.endTime,
                score: fallback.score,
                weather: fallback.weather,
                reasonSummary: fallback.reasonSummary,
                locationName: locationService.locationName
            )
        } else {
            self.fallbackWindow = nil
        }

        // Add location to split walk suggestion if it exists
        if let split = result.splitWalkSuggestion {
            let windowsWithLocation = split.windows.map { window in
                GoldenWindow(
                    startTime: window.startTime,
                    endTime: window.endTime,
                    score: window.score,
                    weather: window.weather,
                    reasonSummary: window.reasonSummary,
                    locationName: locationService.locationName
                )
            }
            self.splitWalkSuggestion = SplitWalkSuggestion(
                windows: windowsWithLocation,
                totalDuration: split.totalDuration,
                combinedScore: split.combinedScore
            )
        } else {
            self.splitWalkSuggestion = nil
        }

        self.noWindowReason = result.noWindowReason
    }

    // MARK: - Settings Update
    func updatePreferences(_ newPreferences: UserPreferences) {
        self.preferences = newPreferences

        // Reload mock data with new step goal
        Task {
            await loadMockData()
            calculateGoldenWindow()
        }
    }

    // MARK: - Developer Scenarios
    private func generateDevScenarioResult(scenario: MockScenario) -> WindowResult {
        let calendar = Calendar.current
        let now = Date()

        switch scenario {
        case .normal:
            // Use normal algorithm
            return windowFinder.findAllWindows(
                freeBlocks: calendarService.freeBlocks,
                weatherForecast: weatherService.currentForecast,
                lookAheadHours: 12
            )

        case .fallbackCold:
            // Single fallback window with cold weather
            let window = GoldenWindow(
                startTime: calendar.date(byAdding: .hour, value: 2, to: now)!,
                endTime: calendar.date(byAdding: .minute, value: 140, to: now)!,
                score: 42.0,
                weather: HourlyWeather(
                    time: calendar.date(byAdding: .hour, value: 2, to: now)!,
                    temperature: 48,
                    precipitationProbability: 0.15,
                    uvIndex: 3,
                    weatherCondition: .cloudy
                ),
                reasonSummary: "Best available—a bit chilly at 48°F",
                locationName: nil
            )
            return WindowResult(
                goldenWindows: [],
                fallbackWindow: window,
                splitWalkSuggestion: nil,
                noWindowReason: nil
            )

        case .fallbackRainy:
            // Single fallback window with rain risk
            let window = GoldenWindow(
                startTime: calendar.date(byAdding: .hour, value: 3, to: now)!,
                endTime: calendar.date(byAdding: .minute, value: 200, to: now)!,
                score: 38.0,
                weather: HourlyWeather(
                    time: calendar.date(byAdding: .hour, value: 3, to: now)!,
                    temperature: 62,
                    precipitationProbability: 0.45,
                    uvIndex: 2,
                    weatherCondition: .cloudy
                ),
                reasonSummary: "Best available—45% chance of rain, cloudy",
                locationName: nil
            )
            return WindowResult(
                goldenWindows: [],
                fallbackWindow: window,
                splitWalkSuggestion: nil,
                noWindowReason: .poorWeather
            )

        case .splitWalk:
            // Split walk suggestion scenario
            let window1 = GoldenWindow(
                startTime: calendar.date(byAdding: .hour, value: 2, to: now)!,
                endTime: calendar.date(byAdding: .minute, value: 137, to: now)!,
                score: 72.0,
                weather: HourlyWeather(
                    time: calendar.date(byAdding: .hour, value: 2, to: now)!,
                    temperature: 68,
                    precipitationProbability: 0.1,
                    uvIndex: 4,
                    weatherCondition: .partlyCloudy
                ),
                reasonSummary: "Great for a walk—68°F",
                locationName: nil
            )

            let window2 = GoldenWindow(
                startTime: calendar.date(byAdding: .hour, value: 6, to: now)!,
                endTime: calendar.date(byAdding: .minute, value: 375, to: now)!,
                score: 68.0,
                weather: HourlyWeather(
                    time: calendar.date(byAdding: .hour, value: 6, to: now)!,
                    temperature: 65,
                    precipitationProbability: 0.15,
                    uvIndex: 2,
                    weatherCondition: .partlyCloudy
                ),
                reasonSummary: "Good window—65°F",
                locationName: nil
            )

            let suggestion = SplitWalkSuggestion(
                windows: [window1, window2],
                totalDuration: 32,
                combinedScore: 70.0
            )

            return WindowResult(
                goldenWindows: [],
                fallbackWindow: nil,
                splitWalkSuggestion: suggestion,
                noWindowReason: .scheduleTooTight
            )

        case .noFreeTime:
            // Calendar fully booked
            return WindowResult(
                goldenWindows: [],
                fallbackWindow: nil,
                splitWalkSuggestion: nil,
                noWindowReason: .noFreeTime
            )

        case .extremeWeather:
            // Free time but weather is extreme
            return WindowResult(
                goldenWindows: [],
                fallbackWindow: nil,
                splitWalkSuggestion: nil,
                noWindowReason: .unsafeWeather
            )

        case .scheduleTooTight:
            // Free time blocks too short
            return WindowResult(
                goldenWindows: [],
                fallbackWindow: nil,
                splitWalkSuggestion: nil,
                noWindowReason: .scheduleTooTight
            )
        }
    }
}
