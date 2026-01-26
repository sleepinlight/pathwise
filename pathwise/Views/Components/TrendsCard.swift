//
//  TrendsCard.swift
//  pathwise
//
//  Displays long-term activity trends and insights
//

import SwiftUI

struct TrendsCard: View {
    let weeklyActivities: [DailyActivity]
    let stepGoal: Int

    private var weeklyAverage: Int {
        guard !weeklyActivities.isEmpty else { return 0 }
        return weeklyActivities.reduce(0) { $0 + $1.steps } / weeklyActivities.count
    }

    private var totalDistance: Double {
        weeklyActivities.reduce(0) { $0 + $1.distance }
    }

    private var totalMinutes: Int {
        weeklyActivities.reduce(0) { $0 + $1.minutesMoved }
    }

    private var consistencyScore: Double {
        // Calculate consistency as percentage of days meeting at least 50% of goal
        let daysAboveHalfGoal = weeklyActivities.filter { $0.steps >= stepGoal / 2 }.count
        return Double(daysAboveHalfGoal) / Double(max(weeklyActivities.count, 1))
    }

    private var trend: Trend {
        guard weeklyActivities.count >= 2 else { return .stable }

        // Compare first half vs second half of week
        let midpoint = weeklyActivities.count / 2
        let firstHalf = weeklyActivities.prefix(midpoint)
        let secondHalf = weeklyActivities.suffix(weeklyActivities.count - midpoint)

        let firstAvg = firstHalf.reduce(0) { $0 + $1.steps } / max(firstHalf.count, 1)
        let secondAvg = secondHalf.reduce(0) { $0 + $1.steps } / max(secondHalf.count, 1)

        let difference = Double(secondAvg - firstAvg) / Double(max(firstAvg, 1))

        if difference > 0.15 {
            return .improving
        } else if difference < -0.15 {
            return .declining
        } else {
            return .stable
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.title3)
                    .foregroundColor(.accent)

                Text("Weekly Trends")
                    .font(.pathwiseSubheadline)
                    .foregroundColor(.primaryText)

                Spacer()

                // Trend Badge
                HStack(spacing: Spacing.xs) {
                    Image(systemName: trend.icon)
                        .foregroundColor(trend.color)
                        .font(.caption)

                    Text(trend.text)
                        .font(.pathwiseCaption)
                        .fontWeight(.semibold)
                        .foregroundColor(trend.color)
                }
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xs)
                .background(trend.color.opacity(0.15))
                .cornerRadius(CornerRadius.sm)
            }

            // Stats Grid
            VStack(spacing: Spacing.sm) {
                HStack(spacing: Spacing.md) {
                    TrendStat(
                        icon: "figure.walk",
                        value: "\(weeklyAverage)",
                        label: "Daily Avg",
                        color: .accent
                    )

                    Divider()
                        .frame(height: 40)

                    TrendStat(
                        icon: "flame.fill",
                        value: "\(Int(consistencyScore * 100))%",
                        label: "Consistency",
                        color: .secondaryAccent
                    )
                }

                Divider()

                HStack(spacing: Spacing.md) {
                    TrendStat(
                        icon: "location.fill",
                        value: String(format: "%.1f", totalDistance),
                        label: "Total Miles",
                        color: .accent
                    )

                    Divider()
                        .frame(height: 40)

                    TrendStat(
                        icon: "timer",
                        value: "\(totalMinutes)",
                        label: "Total Mins",
                        color: .secondaryAccent
                    )
                }
            }
            .padding(.top, Spacing.xs)

            // Insight Text
            if let insight = generateInsight() {
                Divider()

                HStack(alignment: .top, spacing: Spacing.sm) {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundColor(.accent.opacity(0.7))
                        .padding(.top, 2)

                    Text(insight)
                        .font(.pathwiseCaption)
                        .foregroundColor(.primaryText.opacity(0.8))
                        .lineSpacing(4)
                }
                .padding(Spacing.sm)
                .background(Color.accent.opacity(0.05))
                .cornerRadius(CornerRadius.sm)
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .pathwiseCardShadow()
    }

    private func generateInsight() -> String? {
        let goalPercentage = Double(weeklyAverage) / Double(stepGoal)

        switch (trend, goalPercentage, consistencyScore) {
        case (.improving, _, _):
            return "Great momentum! Your activity is trending upward this week. Keep it up!"

        case (.declining, _, let consistency) where consistency < 0.5:
            return "Activity has dropped this week. Try to use more golden windows to get back on track."

        case (_, let goal, _) where goal >= 1.0:
            return "Excellent! You're averaging above your daily step goal. Consider increasing your goal to keep challenging yourself."

        case (_, let goal, _) where goal >= 0.8:
            return "You're close to your goal! A few more golden window walks could push you over the edge."

        case (_, _, let consistency) where consistency >= 0.8:
            return "Impressive consistency! You're staying active most days, which builds lasting habits."

        default:
            return "Focus on hitting golden windows consistently to build a sustainable routine."
        }
    }
}

struct TrendStat: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(color)

            Text(value)
                .font(.pathwiseTitle)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)

            Text(label)
                .font(.pathwiseCaption)
                .foregroundColor(.primaryText.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}

enum Trend {
    case improving
    case stable
    case declining

    var text: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        }
    }

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var color: Color {
        switch self {
        case .improving: return .green
        case .stable: return .blue
        case .declining: return .orange
        }
    }
}

#Preview {
    let calendar = Calendar.current
    let activities = (0..<7).map { dayOffset in
        let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
        let steps = 6000 + (dayOffset * 500) // Improving trend
        return DailyActivity(
            date: calendar.startOfDay(for: date),
            steps: steps,
            distance: Double(steps) / 2000.0,
            minutesMoved: steps / 150,
            claimedWindow: steps >= 8000
        )
    }

    return TrendsCard(
        weeklyActivities: activities,
        stepGoal: 8000
    )
    .padding()
    .background(Color.primaryBackground)
}
