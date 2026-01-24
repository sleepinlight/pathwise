//
//  ContentView.swift
//  pathwise
//
//  Created by Andy Carter on 1/23/26.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var onboardingState = OnboardingState()
    @StateObject private var themeManager = ThemeManager()

    var body: some View {
        Group {
            if onboardingState.hasCompletedOnboarding {
                DashboardView()
            } else {
                OnboardingView(isOnboardingComplete: $onboardingState.hasCompletedOnboarding)
            }
        }
        .animation(.easeInOut, value: onboardingState.hasCompletedOnboarding)
        .preferredColorScheme(themeManager.colorScheme)
        .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { _ in
            themeManager.updateTheme()
        }
    }
}

// Theme Manager to handle theme changes
@MainActor
class ThemeManager: ObservableObject {
    @Published var colorScheme: ColorScheme?

    init() {
        updateTheme()
    }

    func updateTheme() {
        if let data = UserDefaults.standard.data(forKey: "userPreferences"),
           let preferences = try? JSONDecoder().decode(UserPreferences.self, from: data) {
            switch preferences.theme {
            case .light:
                colorScheme = .light
            case .dark:
                colorScheme = .dark
            case .system:
                colorScheme = nil // nil means follow system
            }
        } else {
            colorScheme = nil // Default to system
        }
    }
}

extension Notification.Name {
    static let themeDidChange = Notification.Name("themeDidChange")
    static let devScenarioChanged = Notification.Name("devScenarioChanged")
}

#Preview("Onboarding") {
    ContentView()
}

#Preview("Dashboard") {
    DashboardView()
}
