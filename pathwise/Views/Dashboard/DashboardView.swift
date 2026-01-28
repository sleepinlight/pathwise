//
//  DashboardView.swift
//  pathwise
//
//  Main dashboard view
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingSettings = false
    @AppStorage("dynamicBackgroundEnabled") private var dynamicBackgroundEnabled: Bool = true

    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    LoadingSplashView()
                } else {
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            // Header
                            HeaderView(
                                greeting: viewModel.greeting,
                                isInGoldenWindow: viewModel.isInGoldenWindow,
                                onSettingsTap: { showingSettings = true }
                            )
                            .padding(.horizontal, Spacing.lg)
                            .padding(.top, Spacing.md)

                            // Golden Window Card
                            GoldenWindowCard(
                                goldenWindows: viewModel.goldenWindows,
                                fallbackWindow: viewModel.fallbackWindow,
                                splitWalkSuggestion: viewModel.splitWalkSuggestion,
                                noWindowReason: viewModel.noWindowReason,
                                isInGoldenWindow: viewModel.isInGoldenWindow,
                                activeWeatherAlerts: viewModel.activeWeatherAlerts,
                                isCalendarBlocking: viewModel.isCalendarBlocking,
                                onShowMeAnyway: {
                                    viewModel.handleShowMeAnyway()
                                }
                            )
                            .padding(.horizontal, Spacing.lg)

                            // Activity Stats
                            ActivityStatsCard(
                                steps: viewModel.todaySteps,
                                distance: viewModel.todayDistance,
                                minutes: viewModel.todayMinutes,
                                stepGoal: viewModel.preferences.dailyStepGoal,
                                averagePace: viewModel.averagePace,
                                averageHeartRate: viewModel.averageHeartRate,
                                activeCalories: viewModel.activeCalories
                            )
                            .padding(.horizontal, Spacing.lg)

                            // Weekly Chart
                            if !viewModel.weeklyActivities.isEmpty {
                                WeeklyActivityChart(
                                    weeklyActivities: viewModel.weeklyActivities,
                                    stepGoal: viewModel.preferences.dailyStepGoal
                                )
                                .padding(.horizontal, Spacing.lg)

                                // Trends Card
                                TrendsCard(
                                    weeklyActivities: viewModel.weeklyActivities,
                                    stepGoal: viewModel.preferences.dailyStepGoal
                                )
                                .padding(.horizontal, Spacing.lg)
                            }

                            Spacer(minLength: Spacing.xl)
                        }
                        .padding(.bottom, Spacing.xl)
                    }
                    .background(
                        Group {
                            if dynamicBackgroundEnabled {
                                DynamicBackgroundView()
                            } else {
                                Color.primaryBackground.ignoresSafeArea()
                            }
                        }
                    )
                    .refreshable {
                        await viewModel.refresh()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .onChange(of: showingSettings) { _, isShowing in
                // When settings sheet is dismissed, refresh data with new preferences
                if !isShowing {
                    Task {
                        await viewModel.refresh()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .devScenarioChanged)) { _ in
                // Refresh when dev scenario changes
                Task {
                    await viewModel.refresh()
                }
            }
        }
        .task {
            await viewModel.initialize()
        }
    }
}

struct HeaderView: View {
    @Environment(\.dynamicForegroundColor) private var dynamicForeground

    let greeting: String
    let isInGoldenWindow: Bool
    let onSettingsTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(greeting)
                        .font(.pathwiseTitle)
                        .foregroundColor(dynamicForeground)

                    Text(isInGoldenWindow ? "It's a great time for a walk!" : "Find your perfect walking window")
                        .font(.pathwiseBody)
                        .foregroundColor(dynamicForeground.opacity(0.6))
                }

                Spacer()

                // Settings button
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(dynamicForeground)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
