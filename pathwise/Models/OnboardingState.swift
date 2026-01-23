//
//  OnboardingState.swift
//  pathwise
//
//  Onboarding state management
//

import Foundation
import Combine

class OnboardingState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    @Published var currentPage: Int = 0

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        currentPage = 0
    }
}

enum OnboardingPage: Int, CaseIterable {
    case welcome = 0
    case howItWorks = 1
    case calendar = 2
    case weather = 3
    case health = 4
    case notifications = 5
    case ready = 6

    var title: String {
        switch self {
        case .welcome:
            return "Welcome to Pathwise"
        case .howItWorks:
            return "Find Your Golden Window"
        case .calendar:
            return "Connect Your Calendar"
        case .weather:
            return "Check the Weather"
        case .health:
            return "Track Your Progress"
        case .notifications:
            return "Get Daily Nudges"
        case .ready:
            return "You're All Set!"
        }
    }

    var subtitle: String {
        switch self {
        case .welcome:
            return "Your proactive walking concierge"
        case .howItWorks:
            return "We analyze your schedule and weather to find the perfect time for a walk"
        case .calendar:
            return "We'll find free time in your day for a refreshing walk"
        case .weather:
            return "We'll check conditions to ensure comfortable walking weather"
        case .health:
            return "See your steps, distance, and celebrate your walking streaks"
        case .notifications:
            return "Get a friendly reminder each morning about your perfect walking window"
        case .ready:
            return "Let's find your first Golden Window"
        }
    }

    var iconName: String {
        switch self {
        case .welcome:
            return "figure.walk.circle.fill"
        case .howItWorks:
            return "sparkles"
        case .calendar:
            return "calendar"
        case .weather:
            return "cloud.sun.fill"
        case .health:
            return "heart.fill"
        case .notifications:
            return "bell.fill"
        case .ready:
            return "checkmark.circle.fill"
        }
    }

    var requiresPermission: Bool {
        switch self {
        case .calendar, .weather, .health, .notifications:
            return true
        default:
            return false
        }
    }
}
