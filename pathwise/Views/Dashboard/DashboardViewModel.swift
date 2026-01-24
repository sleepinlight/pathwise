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
    @Published var goldenWindow: GoldenWindow?
    @Published var todaySteps: Int = 0
    @Published var todayDistance: Double = 0.0
    @Published var todayMinutes: Int = 0
    @Published var weeklyActivities: [DailyActivity] = []
    @Published var preferences = UserPreferences()
    @Published var isLoading = false

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
        guard let window = windowFinder.findGoldenWindow(
            freeBlocks: calendarService.freeBlocks,
            weatherForecast: weatherService.currentForecast,
            lookAheadHours: 12
        ) else {
            self.goldenWindow = nil
            return
        }

        // Add location name to the window
        let windowWithLocation = GoldenWindow(
            startTime: window.startTime,
            endTime: window.endTime,
            score: window.score,
            weather: window.weather,
            reasonSummary: window.reasonSummary,
            locationName: locationService.locationName
        )

        self.goldenWindow = windowWithLocation
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
}
