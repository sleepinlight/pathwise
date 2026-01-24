//
//  WeeklyActivityChart.swift
//  pathwise
//
//  Weekly activity bar chart showing window claims
//

import SwiftUI

struct WeeklyActivityChart: View {
    let weeklyActivities: [DailyActivity]
    var stepGoal: Int = 8000 // Default goal, can be customized

    private var maxSteps: Int {
        // Use the max of either the highest steps OR the goal, so bars scale properly
        max(weeklyActivities.map { $0.steps }.max() ?? 1, stepGoal)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundColor(.accent)

                Text("Weekly Overview")
                    .font(.pathwiseSubheadline)
                    .foregroundColor(.primaryText)

                Spacer()

                // Windows Claimed Badge
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accent)
                        .font(.caption)

                    Text("\(windowsClaimedCount) Windows")
                        .font(.pathwiseCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(.accent)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(Color.accent.opacity(0.15))
                .cornerRadius(CornerRadius.sm)
            }

            // Bar Chart
            VStack(spacing: Spacing.md) {
                // Bars
                HStack(alignment: .bottom, spacing: Spacing.sm) {
                    ForEach(weeklyActivities) { activity in
                        BarColumnView(
                            activity: activity,
                            maxSteps: maxSteps,
                            stepGoal: stepGoal
                        )
                    }
                }
                .frame(height: 100)

                // Day Labels (separate row below bars with more spacing)
                HStack(spacing: Spacing.sm) {
                    ForEach(weeklyActivities) { activity in
                        DayLabel(activity: activity)
                    }
                }
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .pathwiseCardShadow()
    }

    private var windowsClaimedCount: Int {
        weeklyActivities.filter { $0.claimedWindow }.count
    }
}

// Bar column component (just the bar)
struct BarColumnView: View {
    let activity: DailyActivity
    let maxSteps: Int
    let stepGoal: Int

    private var barHeight: CGFloat {
        guard maxSteps > 0 else { return 0 }
        return CGFloat(activity.steps) / CGFloat(maxSteps)
    }

    private var goalProgress: Double {
        guard stepGoal > 0 else { return 0 }
        return Double(activity.steps) / Double(stepGoal)
    }

    private var barColor: Color {
        if goalProgress >= 1.0 {
            // Goal met or exceeded - darkest shade
            return Color.accent
        } else if goalProgress >= 0.5 {
            // More than half - medium shade
            return Color.accent.opacity(0.6)
        } else {
            // Less than half - lightest shade
            return Color.accent.opacity(0.3)
        }
    }

    private var showCheckmark: Bool {
        // Only show checkmark if goal is met AND bar is tall enough
        goalProgress >= 1.0
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(activity.date)
    }

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()

                ZStack {
                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(barColor)
                        .frame(height: max(geometry.size.height * barHeight, 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .strokeBorder(
                                    isToday ? Color.accent : Color.clear,
                                    lineWidth: 2
                                )
                        )

                    // Checkmark icon for met/exceeded goals
                    if showCheckmark && geometry.size.height * barHeight > 30 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .offset(y: -(geometry.size.height * barHeight / 2) + 12)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// Day label component (separate from bar)
struct DayLabel: View {
    let activity: DailyActivity

    private var dayInitial: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let dayName = formatter.string(from: activity.date)
        return String(dayName.prefix(1))
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(activity.date)
    }

    var body: some View {
        Text(dayInitial)
            .font(.pathwiseCaption)
            .fontWeight(isToday ? .bold : .regular)
            .foregroundColor(isToday ? .accent : .primaryText.opacity(0.6))
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    let calendar = Calendar.current
    let mockActivities = (0..<7).map { dayOffset in
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
        return DailyActivity(
            date: calendar.startOfDay(for: date),
            steps: Int.random(in: 3000...9000),
            distance: Double.random(in: 1.5...4.5),
            minutesMoved: Int.random(in: 20...60),
            claimedWindow: Bool.random()
        )
    }.sorted { $0.date < $1.date }

    return WeeklyActivityChart(weeklyActivities: mockActivities)
        .padding()
        .background(Color.primaryBackground)
}
