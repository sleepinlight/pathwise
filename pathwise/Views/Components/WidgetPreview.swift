//
//  WidgetPreview.swift
//  pathwise
//
//  Widget design previews (actual widgets require Widget Extension target)
//

import SwiftUI

// MARK: - Small Widget Preview
struct SmallWidgetPreview: View {
    let window: GoldenWindow?

    var body: some View {
        ZStack {
            Color.cardBackground

            if let window = window {
                VStack(spacing: Spacing.xs) {
                    // Icon
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.accent)

                    // Time
                    Text(window.timeString)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.accent)

                    // Weather
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: window.weather.weatherCondition.sfSymbol)
                            .font(.caption)
                            .foregroundColor(.primaryText)

                        Text("\(Int(window.weather.temperature))°F")
                            .font(.pathwiseCaption)
                            .foregroundColor(.primaryText)
                    }
                }
                .padding(Spacing.md)
            } else {
                VStack(spacing: Spacing.xs) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title2)
                        .foregroundColor(.primaryText.opacity(0.3))

                    Text("No Window")
                        .font(.pathwiseCaption)
                        .foregroundColor(.primaryText.opacity(0.6))
                }
                .padding(Spacing.md)
            }
        }
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Medium Widget Preview
struct MediumWidgetPreview: View {
    let window: GoldenWindow?
    let steps: Int

    var body: some View {
        ZStack {
            Color.cardBackground

            if let window = window {
                HStack(spacing: Spacing.md) {
                    // Left: Golden Window Info
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Image(systemName: "sparkles")
                                .font(.caption)
                                .foregroundColor(.accent)

                            Text("Golden Window")
                                .font(.pathwiseCaption)
                                .foregroundColor(.primaryText)
                        }

                        Text(window.timeString)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.accent)

                        HStack(spacing: Spacing.xs) {
                            Image(systemName: window.weather.weatherCondition.sfSymbol)
                                .font(.caption)
                                .foregroundColor(.primaryText)

                            Text("\(Int(window.weather.temperature))°F")
                                .font(.pathwiseCaption)
                                .foregroundColor(.primaryText)
                        }

                        Text(window.statusDescription)
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.accent)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(Color.accent.opacity(0.15))
                            .cornerRadius(4)
                    }

                    Divider()

                    // Right: Mini Timeline + Steps
                    VStack(alignment: .trailing, spacing: Spacing.xs) {
                        // Steps
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(steps)")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.primaryText)

                            Text("steps today")
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundColor(.primaryText.opacity(0.6))
                        }

                        Spacer()

                        // Progress indicator
                        HStack(spacing: 4) {
                            ForEach(0..<4) { index in
                                Circle()
                                    .fill(index < 2 ? Color.accent : Color.accent.opacity(0.2))
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                }
                .padding(Spacing.md)
            } else {
                HStack {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.title)
                        .foregroundColor(.primaryText.opacity(0.3))

                    Text("No Golden Window available today")
                        .font(.pathwiseBody)
                        .foregroundColor(.primaryText.opacity(0.6))
                }
                .padding(Spacing.md)
            }
        }
        .cornerRadius(CornerRadius.lg)
    }
}

// MARK: - Preview
#Preview("Small Widget") {
    VStack(spacing: 20) {
        SmallWidgetPreview(window: GoldenWindow(
            startTime: Date(),
            endTime: Date().addingTimeInterval(1200),
            score: 85.0,
            weather: HourlyWeather(
                time: Date(),
                temperature: 72,
                precipitationProbability: 0.1,
                uvIndex: 5,
                weatherCondition: .clear
            ),
            reasonSummary: "Perfect conditions",
            locationName: "Austin, TX"
        ))
        .frame(width: 155, height: 155)

        SmallWidgetPreview(window: nil)
            .frame(width: 155, height: 155)
    }
    .padding()
    .background(Color.primaryBackground)
}

#Preview("Medium Widget") {
    VStack(spacing: 20) {
        MediumWidgetPreview(
            window: GoldenWindow(
                startTime: Date(),
                endTime: Date().addingTimeInterval(1200),
                score: 85.0,
                weather: HourlyWeather(
                    time: Date(),
                    temperature: 72,
                    precipitationProbability: 0.1,
                    uvIndex: 5,
                    weatherCondition: .clear
                ),
                reasonSummary: "Perfect conditions",
                locationName: "Austin, TX"
            ),
            steps: 5432
        )
        .frame(width: 329, height: 155)

        MediumWidgetPreview(window: nil, steps: 3210)
            .frame(width: 329, height: 155)
    }
    .padding()
    .background(Color.primaryBackground)
}
