//
//  TrendsView.swift
//  pathwise
//
//  Trends and analytics view showing weekly activity patterns
//

import SwiftUI

struct TrendsView: View {
    @StateObject private var viewModel = TrendsViewModel()
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
                            TrendsHeaderView()
                                .padding(.horizontal, Spacing.lg)
                                .padding(.top, Spacing.md)

                            // Weekly Chart
                            if !viewModel.weeklyActivities.isEmpty {
                                WeeklyActivityChart(
                                    weeklyActivities: viewModel.weeklyActivities,
                                    stepGoal: viewModel.stepGoal
                                )
                                .padding(.horizontal, Spacing.lg)

                                // Trends Card
                                TrendsCard(
                                    weeklyActivities: viewModel.weeklyActivities,
                                    stepGoal: viewModel.stepGoal
                                )
                                .padding(.horizontal, Spacing.lg)
                            } else {
                                EmptyTrendsView()
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
        }
        .task {
            await viewModel.initialize()
        }
    }
}

struct TrendsHeaderView: View {
    @Environment(\.dynamicForegroundColor) private var dynamicForeground

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text("Activity Trends")
                .font(.pathwiseTitle)
                .foregroundColor(dynamicForeground)

            Text("Your weekly walking patterns and insights")
                .font(.pathwiseBody)
                .foregroundColor(dynamicForeground.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyTrendsView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundColor(.primaryText.opacity(0.3))

            VStack(spacing: Spacing.xs) {
                Text("No Activity Data Yet")
                    .font(.pathwiseSubheadline)
                    .foregroundColor(.primaryText)

                Text("Start using golden windows to see your weekly trends here")
                    .font(.pathwiseBody)
                    .foregroundColor(.primaryText.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(Spacing.xxl)
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .pathwiseCardShadow()
    }
}

#Preview {
    TrendsView()
}
