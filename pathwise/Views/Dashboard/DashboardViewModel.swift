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
    @Published var isInGoldenWindow: Bool = false
    @Published var activeWeatherAlerts: [WeatherAlert] = []
    @Published var isCalendarBlocking: Bool = false
    @Published var isIgnoringCalendar: Bool = false
    @Published var todaySteps: Int = 0
    @Published var todayDistance: Double = 0.0
    @Published var todayMinutes: Int = 0
    @Published var averagePace: Double? = nil  // min/mile
    @Published var averageHeartRate: Int? = nil  // bpm
    @Published var activeCalories: Double = 0.0  // kcal
    @Published var weeklyActivities: [DailyActivity] = []
    @Published var preferences = UserPreferences()
    @Published var isLoading = false

    // Notification preferences change observer
    private var prefsObserver: NSObjectProtocol?

    init() {
        // Observe preference changes to re-evaluate scheduled notifications
        prefsObserver = NotificationCenter.default.addObserver(forName: Notification.Name("PreferencesDidChange"), object: nil, queue: .main) { [weak self] _ in
            self?.updateNotificationsIfNeeded()
        }
    }

    deinit {
        if let obs = prefsObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

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

        let dev = DeveloperSettings.shared
        if dev.isEnabled && dev.enableMocks {
            await loadMockData()
        } else {
            await loadRealData()
        }

        // Calculate the Golden Window
        calculateGoldenWindow()

        isLoading = false
    }

    func refresh() async {
        // Reload preferences in case they changed in settings
        loadPreferences()

        let dev = DeveloperSettings.shared
        if dev.isEnabled && dev.enableMocks {
            await loadMockData()
        } else {
            await loadRealData()
        }
        calculateGoldenWindow()
    }

    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: "userPreferences"),
           let savedPreferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            self.preferences = savedPreferences
        }
    }

    // MARK: - Real Data Loading
    private func loadRealData() async {
        // Request permissions
        async let calendarAccess = calendarService.requestCalendarAccess()
        async let healthAccess = healthService.requestHealthAccess()

        let (hasCalendar, hasHealth) = await (calendarAccess, healthAccess)

        // Request location permission and location
        await locationService.requestLocationPermission()
        await locationService.requestLocation()

        let location = locationService.currentLocation

        // Fetch weather for current location if available, else clear forecast
        if let location = location {
            print("📍 DashboardViewModel: Location available, fetching weather")
            await weatherService.fetchWeather(for: location)
        } else {
            print("⚠️ DashboardViewModel: No location available, cannot fetch weather")
            weatherService.currentForecast = []
            weatherService.error = .locationUnavailable
        }

        // Fetch data concurrently
        async let calendar = calendarService.fetchTodayEvents()
        async let todayActivity = healthService.fetchTodayActivity()
        async let weeklyActivity = healthService.fetchWeeklyActivity()

        _ = await (calendar, todayActivity, weeklyActivity)

        // Update published properties
        self.todaySteps = healthService.todaySteps
        self.todayDistance = healthService.todayDistance
        self.todayMinutes = healthService.todayMinutesMoved
        self.activeCalories = healthService.todayActiveCalories
        self.averageHeartRate = healthService.todayAverageHeartRate
        self.weeklyActivities = healthService.weeklyActivities

        // Calculate average pace if we have distance and time data
        if healthService.todayDistance > 0 && healthService.todayMinutesMoved > 0 {
            self.averagePace = Double(healthService.todayMinutesMoved) / healthService.todayDistance
        } else {
            self.averagePace = nil
        }
    }

    // MARK: - Mock Data Loading
    private func loadMockData() async {
        let dev = DeveloperSettings.shared
        guard dev.isEnabled && dev.enableMocks else { return }

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
        self.activeCalories = healthService.todayActiveCalories
        self.averageHeartRate = healthService.todayAverageHeartRate
        self.weeklyActivities = healthService.weeklyActivities

        // Calculate average pace if we have distance and time data
        if healthService.todayDistance > 0 && healthService.todayMinutesMoved > 0 {
            self.averagePace = Double(healthService.todayMinutesMoved) / healthService.todayDistance
        } else {
            self.averagePace = nil
        }

        // Update widget after loading activity data
        updateWidgetData()
    }

    // MARK: - Golden Window Calculation
    private func calculateGoldenWindow() {
        // Check if dev mode is enabled with a specific scenario
        let devSettings = DeveloperSettings.shared
        let result: WindowResult

        if devSettings.isEnabled && devSettings.enableMocks && devSettings.currentScenario != .normal {
            result = generateDevScenarioResult(scenario: devSettings.currentScenario)
        } else {
            // Get active weather alerts from WeatherService
            let alerts = weatherService.weatherAlerts

            result = windowFinder.findAllWindows(
                freeBlocks: calendarService.freeBlocks,
                weatherForecast: weatherService.currentForecast,
                activeWeatherAlerts: alerts,
                ignoreCalendar: isIgnoringCalendar,
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
        self.isInGoldenWindow = result.isInGoldenWindow
        self.activeWeatherAlerts = result.activeWeatherAlerts
        self.isCalendarBlocking = result.isCalendarBlocking

        // Update widget with new data
        updateWidgetData()

        // Update notifications according to current preferences and windows
        updateNotificationsIfNeeded()
    }

    // MARK: - Notifications
    private func updateNotificationsIfNeeded() {
        // Read preferences from stored values
        let notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        let windowReminderEnabled = UserDefaults.standard.bool(forKey: "windowReminderEnabled")
        let notificationTime = preferences.morningNotificationTime

        // Clear any existing schedules to avoid duplicates
        NotificationService.shared.cancelDailyNudge()
        NotificationService.shared.cancelWindowReminder()

        guard notificationsEnabled else { return }

        // Use first golden window if available, or fallback
        if let window = goldenWindows.first ?? fallbackWindow {
            NotificationService.shared.scheduleDailyNudge(for: window, notificationTime: notificationTime)

            if windowReminderEnabled {
                NotificationService.shared.scheduleWindowReminder(for: window, minutesBefore: 15)
            }
        }
    }

    // MARK: - Widget Data Update
    private func updateWidgetData() {
        let widgetData = PathwiseWidgetDataManager.createPathwiseWidgetData(
            goldenWindow: goldenWindows.first,
            additionalWindows: Array(goldenWindows.dropFirst().prefix(2)),
            fallbackWindow: fallbackWindow,
            noWindowReason: noWindowReason,
            todaySteps: todaySteps,
            stepGoal: preferences.dailyStepGoal,
            isInGoldenWindow: isInGoldenWindow,
            theme: preferences.theme,
            darkModeStyle: preferences.darkModeStyle
        )

        PathwiseWidgetDataManager.shared.savePathwiseWidgetData(widgetData)
    }

    // MARK: - Show Me Anyway Action
    func handleShowMeAnyway() {
        isIgnoringCalendar = true
        calculateGoldenWindow()
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

        case .inGoldenWindow:
            // User is currently in a golden window
            let window = GoldenWindow(
                startTime: calendar.date(byAdding: .minute, value: -5, to: now)!,
                endTime: calendar.date(byAdding: .minute, value: 15, to: now)!,
                score: 85.0,
                weather: HourlyWeather(
                    time: now,
                    temperature: 72,
                    precipitationProbability: 0.05,
                    uvIndex: 4,
                    weatherCondition: .clear
                ),
                reasonSummary: "Perfect conditions—72°F, clear skies",
                locationName: nil
            )
            return WindowResult(
                goldenWindows: [window],
                fallbackWindow: nil,
                splitWalkSuggestion: nil,
                noWindowReason: nil,
                isInGoldenWindow: true,
                activeWeatherAlerts: [],
                calendarWasConsidered: false
            )

        case .continuousWindow:
            // Continuous time range (3+ hours of good weather)
            let window = GoldenWindow(
                startTime: calendar.date(byAdding: .minute, value: 30, to: now)!,
                endTime: calendar.date(byAdding: .hour, value: 3, to: now)!,
                score: 88.0,
                weather: HourlyWeather(
                    time: calendar.date(byAdding: .minute, value: 30, to: now)!,
                    temperature: 70,
                    precipitationProbability: 0.0,
                    uvIndex: 5,
                    weatherCondition: .clear
                ),
                reasonSummary: "Ideal conditions—70°F, clear skies",
                locationName: nil
            )
            return WindowResult(
                goldenWindows: [window],
                fallbackWindow: nil,
                splitWalkSuggestion: nil,
                noWindowReason: nil,
                isInGoldenWindow: false,
                activeWeatherAlerts: [],
                calendarWasConsidered: false
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
                noWindowReason: nil,
                isInGoldenWindow: false,
                activeWeatherAlerts: [],
                calendarWasConsidered: false
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
                noWindowReason: .poorWeather,
                isInGoldenWindow: false,
                activeWeatherAlerts: [],
                calendarWasConsidered: false
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
                noWindowReason: .scheduleTooTight,
                isInGoldenWindow: false,
                activeWeatherAlerts: [],
                calendarWasConsidered: false
            )

        case .noFreeTime:
            // Calendar fully booked
            return WindowResult(
                goldenWindows: [],
                fallbackWindow: nil,
                splitWalkSuggestion: nil,
                noWindowReason: .noFreeTime,
                isInGoldenWindow: false,
                activeWeatherAlerts: [],
                calendarWasConsidered: false
            )

        case .extremeWeather:
            // Free time but weather is extreme
            return WindowResult(
                goldenWindows: [],
                fallbackWindow: nil,
                splitWalkSuggestion: nil,
                noWindowReason: .unsafeWeather,
                isInGoldenWindow: false,
                activeWeatherAlerts: [],
                calendarWasConsidered: false
            )

        case .scheduleTooTight:
            // Free time blocks too short
            return WindowResult(
                goldenWindows: [],
                fallbackWindow: nil,
                splitWalkSuggestion: nil,
                noWindowReason: .scheduleTooTight,
                isInGoldenWindow: false,
                activeWeatherAlerts: [],
                calendarWasConsidered: false
            )
        }
    }
}

