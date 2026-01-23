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

    private var stepProgress: Double {
        min(Double(steps) / Double(stepGoal), 1.0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: "figure.walk")
                    .font(.title3)
                    .foregroundColor(.accent)

                Text("Today's Activity")
                    .font(.pathwiseSubheadline)
                    .foregroundColor(.primaryText)

                Spacer()
            }

            // Stats Grid
            HStack(spacing: Spacing.md) {
                StatItem(
                    icon: "flame.fill",
                    value: "\(steps)",
                    label: "Steps",
                    color: .orange
                )

                Divider()
                    .frame(height: 50)

                StatItem(
                    icon: "location.fill",
                    value: String(format: "%.1f", distance),
                    label: "Miles",
                    color: .blue
                )

                Divider()
                    .frame(height: 50)

                StatItem(
                    icon: "timer",
                    value: "\(minutes)",
                    label: "Minutes",
                    color: .green
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
        stepGoal: 8000
    )
    .padding()
    .background(Color.primaryBackground)
}
