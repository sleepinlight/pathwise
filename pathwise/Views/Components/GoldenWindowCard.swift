//
//  GoldenWindowCard.swift
//  pathwise
//
//  The main "Golden Window" display card
//

import SwiftUI

struct GoldenWindowCard: View {
    let window: GoldenWindow?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if let window = window {
                // Header
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.accent)

                    Text("Your Golden Window")
                        .font(.pathwiseSubheadline)
                        .foregroundColor(.primaryText)

                    Spacer()

                    StatusBadge(status: window.statusDescription)
                }

                Divider()

                // Time Display
                HStack(alignment: .center, spacing: Spacing.lg) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(window.timeString)
                            .font(.pathwiseLargeNumber)
                            .foregroundColor(.accent)

                        Text("\(window.durationInMinutes) minute walk")
                            .font(.pathwiseBody)
                            .foregroundColor(.primaryText.opacity(0.7))
                    }

                    Spacer()

                    // Weather Icon
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: window.weather.weatherCondition.sfSymbol)
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(.accent)
                            .symbolRenderingMode(.hierarchical)

                        Text("\(Int(window.weather.temperature))°F")
                            .font(.pathwiseHeadline)
                            .foregroundColor(.primaryText)
                    }
                }

                // Reason Summary
                HStack(alignment: .top, spacing: Spacing.xs) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.accent.opacity(0.6))
                        .frame(width: 16, height: 16)
                        .padding(.top, 2)

                    Text(window.reasonSummary)
                        .font(.pathwiseBody)
                        .foregroundColor(.primaryText.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(nil)
                }
                .padding(.top, Spacing.xs)

                // Location (if available)
                if let locationName = window.locationName {
                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundColor(.accent.opacity(0.6))
                            .frame(width: 16, height: 16)

                        Text(locationName)
                            .font(.pathwiseCaption)
                            .foregroundColor(.primaryText.opacity(0.6))
                    }
                    .padding(.top, 2)
                }
            } else {
                // No window available
                VStack(spacing: Spacing.md) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 44))
                        .foregroundColor(.primaryText.opacity(0.3))

                    Text("No Golden Window Today")
                        .font(.pathwiseHeadline)
                        .foregroundColor(.primaryText)

                    Text("Your schedule is too packed or the weather isn't cooperating. Try again tomorrow!")
                        .font(.pathwiseBody)
                        .foregroundColor(.primaryText.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.lg)
            }
        }
        .padding(Spacing.lg)
        .background(Color.cardBackground)
        .cornerRadius(CornerRadius.lg)
        .pathwiseCardShadow()
    }
}

struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status)
            .font(.pathwiseCaption)
            .fontWeight(.semibold)
            .foregroundColor(.accent)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.accent.opacity(0.15))
            .cornerRadius(CornerRadius.sm)
    }
}

#Preview {
    VStack(spacing: 20) {
        GoldenWindowCard(window: GoldenWindow(
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
            reasonSummary: "Perfect conditions—72°F and clear",
            locationName: "San Francisco, CA"
        ))

        GoldenWindowCard(window: nil)
    }
    .padding()
    .background(Color.primaryBackground)
}
