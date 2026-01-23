//
//  ContentView.swift
//  pathwise
//
//  Created by Andy Carter on 1/23/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var onboardingState = OnboardingState()

    var body: some View {
        Group {
            if onboardingState.hasCompletedOnboarding {
                DashboardView()
            } else {
                OnboardingView(isOnboardingComplete: $onboardingState.hasCompletedOnboarding)
            }
        }
        .animation(.easeInOut, value: onboardingState.hasCompletedOnboarding)
    }
}

#Preview("Onboarding") {
    ContentView()
}

#Preview("Dashboard") {
    DashboardView()
}
