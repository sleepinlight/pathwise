//
//  WeeklyActivityChart.swift
//  pathwise
//
//  Weekly activity bar chart showing window claims
//

import SwiftUI

struct WeeklyActivityChart: View {
    let weeklyActivities: [DailyActivity]

    private var maxSteps: Int {
        weeklyActivities.map { $0.steps }.max() ?? 1
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
            HStack(alignment: .bottom, spacing: Spacing.sm) {
                ForEach(weeklyActivities) { activity in
                    BarView(
                        activity: activity,
                        maxSteps: maxSteps
                    )
                }
            }
            .frame(height: 120)
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

struct BarView: View {
    let activity: DailyActivity
    let maxSteps: Int

    private var barHeight: CGFloat {
        guard maxSteps > 0 else { return 0 }
        return CGFloat(activity.steps) / CGFloat(maxSteps)
    }

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
        VStack(spacing: Spacing.xs) {
            // Bar
            GeometryReader { geometry in
                VStack {
                    Spacer()

                    RoundedRectangle(cornerRadius: CornerRadius.sm)
                        .fill(activity.claimedWindow ? Color.accent : Color.accent.opacity(0.3))
                        .frame(height: max(geometry.size.height * barHeight, 4))
                        .overlay(
                            RoundedRectangle(cornerRadius: CornerRadius.sm)
                                .strokeBorder(
                                    isToday ? Color.accent : Color.clear,
                                    lineWidth: 2
                                )
                        )
                }
            }

            // Day Label
            Text(dayInitial)
                .font(.pathwiseCaption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundColor(isToday ? .accent : .primaryText.opacity(0.6))
        }
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
