//
//  TrendsViewModel.swift
//  pathwise
//
//  View model for trends and analytics
//

import Foundation
import Combine

@MainActor
class TrendsViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var weeklyActivities: [DailyActivity] = []
    @Published var stepGoal: Int = 8000

    private let healthService = HealthService()
    private var preferences = UserPreferences()

    func initialize() async {
        isLoading = true
        loadPreferences()

        // Request health access if needed (not in mock mode)
        let dev = DeveloperSettings.shared
        if !dev.isEnabled || !dev.enableMocks {
            if !healthService.hasHealthAccess {
                _ = await healthService.requestHealthAccess()
            }
        }

        await loadActivityData()
        isLoading = false
    }

    func refresh() async {
        loadPreferences()
        await loadActivityData()
    }

    private func loadPreferences() {
        if let data = UserDefaults.standard.data(forKey: "userPreferences"),
           let decoded = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            preferences = decoded
            stepGoal = decoded.dailyStepGoal
        }
    }

    private func loadActivityData() async {
        // Check for dev mode
        let dev = DeveloperSettings.shared
        if dev.isEnabled && dev.enableMocks {
            healthService.useMockHealthData(stepGoal: stepGoal)
            print("📊 TrendsViewModel: Loaded mock data, health service has \(healthService.weeklyActivities.count) activities")
        } else {
            await healthService.fetchWeeklyActivity()
            print("📊 TrendsViewModel: Loaded real data, health service has \(healthService.weeklyActivities.count) activities")
        }

        // Update from health service
        await MainActor.run {
            self.weeklyActivities = healthService.weeklyActivities
            print("📊 TrendsViewModel: Updated view with \(self.weeklyActivities.count) activities")
        }
    }
}
