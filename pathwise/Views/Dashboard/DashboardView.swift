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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Header
                    HeaderView(
                        greeting: viewModel.greeting,
                        onSettingsTap: { showingSettings = true }
                    )
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)

                    // Golden Window Card
                    GoldenWindowCard(
                        goldenWindows: viewModel.goldenWindows,
                        fallbackWindow: viewModel.fallbackWindow,
                        splitWalkSuggestion: viewModel.splitWalkSuggestion,
                        noWindowReason: viewModel.noWindowReason
                    )
                    .padding(.horizontal, Spacing.lg)

                    // Activity Stats
                    ActivityStatsCard(
                        steps: viewModel.todaySteps,
                        distance: viewModel.todayDistance,
                        minutes: viewModel.todayMinutes,
                        stepGoal: viewModel.preferences.dailyStepGoal
                    )
                    .padding(.horizontal, Spacing.lg)

                    // Weekly Chart
                    if !viewModel.weeklyActivities.isEmpty {
                        WeeklyActivityChart(
                            weeklyActivities: viewModel.weeklyActivities,
                            stepGoal: viewModel.preferences.dailyStepGoal
                        )
                        .padding(.horizontal, Spacing.lg)
                    }

                    Spacer(minLength: Spacing.xl)
                }
                .padding(.bottom, Spacing.xl)
            }
            .background(Color.primaryBackground.ignoresSafeArea())
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refresh()
            }
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
    let greeting: String
    let onSettingsTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(greeting)
                        .font(.pathwiseTitle)
                        .foregroundColor(.primaryText)

                    Text("Find your perfect walking window")
                        .font(.pathwiseBody)
                        .foregroundColor(.primaryText.opacity(0.6))
                }

                Spacer()

                // Settings button
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.accent)
                }
            }
        }
    }
}

#Preview {
    DashboardView()
}
