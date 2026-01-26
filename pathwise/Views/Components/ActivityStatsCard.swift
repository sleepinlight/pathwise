//
//  ActivityStatsCard.swift
//  pathwise
//
//  Daily activity stats display (steps, distance, minutes)
//

import SwiftUI

struct ActivityStatsCard: View {
    let steps: Int
    let distance: Double
    let minutes: Int
    let stepGoal: Int
    let averagePace: Double? // min/mile
    let averageHeartRate: Int? // bpm
    let activeCalories: Double // kcal

    @State private var isExpanded = false

    private var stepProgress: Double {
        min(Double(steps) / Double(stepGoal), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header with expand button
            HStack {
                Image(systemName: "figure.walk")
                    .font(.title3)
                    .foregroundColor(.accent)

                Text("Today's Activity")
                    .font(.pathwiseSubheadline)
                    .foregroundColor(.primaryText)

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.title3)
                        .foregroundColor(.accent.opacity(0.6))
                }
            }

            // Stats Grid
            HStack(spacing: Spacing.md) {
                StatItem(
                    icon: "flame.fill",
                    value: "\(steps)",
                    label: "Steps",
                    color: .secondaryAccent
                )

                Divider()
                    .frame(height: 50)

                StatItem(
                    icon: "location.fill",
                    value: String(format: "%.1f", distance),
                    label: "Miles",
                    color: .accent
                )

                Divider()
                    .frame(height: 50)

                StatItem(
                    icon: "timer",
                    value: "\(minutes)",
                    label: "Minutes",
                    color: .secondaryAccent
                )
            }

            // Progress Bar
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text("Daily Goal Progress")
                        .font(.pathwiseCaption)
                        .foregroundColor(.primaryText.opacity(0.7))

                    Spacer()

                    Text("\(Int(stepProgress * 100))%")
                        .font(.pathwiseCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(.accent)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.accent.opacity(0.15))
                            .frame(height: 8)

                        // Progress
                        RoundedRectangle(cornerRadius: CornerRadius.sm)
                            .fill(Color.accent)
                            .frame(width: geometry.size.width * stepProgress, height: 8)
                            .animation(.easeInOut, value: stepProgress)
                    }
                }
                .frame(height: 8)
            }
            .padding(.top, Spacing.xs)

            // Expanded Section
            if isExpanded {
                Divider()
                    .padding(.vertical, Spacing.xs)

                HStack(spacing: Spacing.md) {
                    if let pace = averagePace {
                        StatItem(
                            icon: "figure.walk.motion",
                            value: String(format: "%.1f", pace),
                            label: "Avg Pace",
                            color: .accent
                        )
                    } else {
                        StatItem(
                            icon: "figure.walk.motion",
                            value: "--",
                            label: "Avg Pace",
                            color: .accent.opacity(0.5)
                        )
                    }

                    Divider()
                        .frame(height: 50)

                    if let hr = averageHeartRate {
                        StatItem(
                            icon: "heart.fill",
                            value: "\(hr)",
                            label: "Avg HR",
                            color: .red
                        )
                    } else {
                        StatItem(
                            icon: "heart.fill",
                            value: "--",
                            label: "Avg HR",
                            color: .red.opacity(0.5)
                        )
                    }

                    Divider()
                        .frame(height: 50)

                    if activeCalories > 0 {
                        StatItem(
                            icon: "flame.fill",
                            value: "\(Int(activeCalories))",
                            label: "Calories",
                            color: .orange
                        )
                    } else {
                        StatItem(
                            icon: "flame.fill",
                            value: "--",
                            label: "Calories",
                            color: .orange.opacity(0.5)
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .pathwiseCardShadow()
    }
}

struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(value)
                .font(.pathwiseHeadline)
                .foregroundColor(.primaryText)

            Text(label)
                .font(.pathwiseCaption)
                .foregroundColor(.primaryText.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ActivityStatsCard(
        steps: 5432,
        distance: 2.4,
        minutes: 42,
        stepGoal: 8000,
        averagePace: 18.5,
        averageHeartRate: 112,
        activeCalories: 245
    )
    .padding()
    .background(Color.primaryBackground)
}
