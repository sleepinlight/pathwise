//
//  DayDetailPopover.swift
//  pathwise
//
//  Popover showing detailed stats for a specific day
//

import SwiftUI

struct DayDetailPopover: View {
    let activity: DailyActivity
    let stepGoal: Int

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: activity.date)
    }

    private var caloriesEstimate: Int {
        // Rough estimate: ~0.04 calories per step
        Int(Double(activity.steps) * 0.04)
    }

    private var goalProgress: Double {
        guard stepGoal > 0 else { return 0 }
        return Double(activity.steps) / Double(stepGoal)
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Date Header
            Text(dateString)
                .font(.pathwiseCaption)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText.opacity(0.7))

            Divider()

            // Stats Grid
            VStack(spacing: Spacing.xs) {
                StatRow(
                    icon: "figure.walk",
                    label: "Steps",
                    value: "\(activity.steps)",
                    color: .accent
                )

                StatRow(
                    icon: "flame.fill",
                    label: "Calories",
                    value: "\(caloriesEstimate)",
                    color: .orange
                )

                StatRow(
                    icon: "location.fill",
                    label: "Distance",
                    value: String(format: "%.1f mi", activity.distance),
                    color: .blue
                )
            }

            // Goal Progress
            if goalProgress > 0 {
                Divider()

                HStack(spacing: Spacing.xs) {
                    Image(systemName: goalProgress >= 1.0 ? "checkmark.circle.fill" : "circle.dashed")
                        .font(.caption)
                        .foregroundColor(goalProgress >= 1.0 ? .green : .primaryText.opacity(0.5))

                    Text(goalProgress >= 1.0 ? "Goal Met!" : "\(Int(goalProgress * 100))% of goal")
                        .font(.pathwiseCaption)
                        .foregroundColor(.primaryText.opacity(0.7))

                    Spacer()
                }
            }
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: CornerRadius.md)
                .fill(Color.cardBackground)
                .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)
        )
        .frame(width: 200)
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .frame(width: 16)

            Text(label)
                .font(.pathwiseCaption)
                .foregroundColor(.primaryText.opacity(0.6))

            Spacer()

            Text(value)
                .font(.pathwiseCaption)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
        }
    }
}

#Preview {
    let activity = DailyActivity(
        date: Date(),
        steps: 8500,
        distance: 4.2,
        minutesMoved: 45,
        claimedWindow: true
    )

    return DayDetailPopover(activity: activity, stepGoal: 8000)
        .padding()
        .background(Color.primaryBackground)
}
