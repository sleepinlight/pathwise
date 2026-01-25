//
//  GoldenWindowCard.swift
//  pathwise
//
//  The main "Golden Window" display card with support for multiple windows
//

import SwiftUI

struct GoldenWindowCard: View {
    let goldenWindows: [GoldenWindow]
    let fallbackWindow: GoldenWindow?
    let splitWalkSuggestion: SplitWalkSuggestion?
    let noWindowReason: NoWindowReason?
    let isInGoldenWindow: Bool

    @State private var currentWindowIndex = 0

    // Legacy initializer for backward compatibility
    init(window: GoldenWindow?) {
        if let window = window {
            self.goldenWindows = [window]
            self.fallbackWindow = nil
            self.splitWalkSuggestion = nil
            self.noWindowReason = nil
            self.isInGoldenWindow = false
        } else {
            self.goldenWindows = []
            self.fallbackWindow = nil
            self.splitWalkSuggestion = nil
            self.noWindowReason = nil
            self.isInGoldenWindow = false
        }
    }

    // New initializer with multiple windows support
    init(goldenWindows: [GoldenWindow], fallbackWindow: GoldenWindow?, splitWalkSuggestion: SplitWalkSuggestion?, noWindowReason: NoWindowReason?, isInGoldenWindow: Bool = false) {
        self.goldenWindows = goldenWindows
        self.fallbackWindow = fallbackWindow
        self.splitWalkSuggestion = splitWalkSuggestion
        self.noWindowReason = noWindowReason
        self.isInGoldenWindow = isInGoldenWindow
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if !goldenWindows.isEmpty {
                // Show golden windows with navigation if multiple
                goldenWindowContent
            } else if let fallback = fallbackWindow {
                // Show fallback window with explanation
                fallbackWindowContent(window: fallback)
            } else if let splitSuggestion = splitWalkSuggestion {
                // Show split walk suggestion
                splitWalkContent(suggestion: splitSuggestion)
            } else {
                // No windows available at all
                noWindowContent
            }
        }
        .padding(Spacing.lg)
        .background(
            ZStack {
                Color.cardBackground
                if isInGoldenWindow {
                    Color.accent.opacity(0.05)
                }
            }
        )
        .cornerRadius(CornerRadius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(isInGoldenWindow ? Color.accent : Color.clear, lineWidth: 2)
        )
        .pathwiseCardShadow()
    }

    // MARK: - Golden Window Content

    private var goldenWindowContent: some View {
        VStack(spacing: Spacing.md) {
            // Header with navigation
            HStack {
                Image(systemName: isInGoldenWindow ? "sparkles.rectangle.stack.fill" : "sparkles")
                    .font(.title3)
                    .foregroundColor(.accent)

                if isInGoldenWindow {
                    Text("You're in your Golden Window!")
                        .font(.pathwiseSubheadline)
                        .foregroundColor(.accent)
                } else if goldenWindows.count > 1 {
                    Text("Golden Window \(currentWindowIndex + 1) of \(goldenWindows.count)")
                        .font(.pathwiseSubheadline)
                        .foregroundColor(.primaryText)
                } else {
                    Text("Your Golden Window")
                        .font(.pathwiseSubheadline)
                        .foregroundColor(.primaryText)
                }

                Spacer()

                StatusBadge(status: goldenWindows[currentWindowIndex].statusDescription)
            }

            // Timeline indicators for multiple windows
            if goldenWindows.count > 1 {
                TimelineView(windows: goldenWindows, currentIndex: $currentWindowIndex)
            }

            Divider()

            // Current window details
            TabView(selection: $currentWindowIndex) {
                ForEach(Array(goldenWindows.enumerated()), id: \.element.id) { index, window in
                    WindowDetailsView(
                        window: window,
                        showWeatherWarning: false,
                        weatherWarningText: nil,
                        uvIndexColor: uvIndexColor
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 200)
        }
    }

    // MARK: - Fallback Window Content

    private func fallbackWindowContent(window: GoldenWindow) -> some View {
        VStack(spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundColor(.secondaryAccent)

                Text("Best Available Window")
                    .font(.pathwiseSubheadline)
                    .foregroundColor(.primaryText)

                Spacer()
            }

            Divider()

            // Window details with warning if weather-related
            WindowDetailsView(
                window: window,
                showWeatherWarning: noWindowReason?.severity != WeatherSeverity.none,
                weatherWarningText: noWindowReason?.rawValue,
                uvIndexColor: uvIndexColor
            )

            // Fallback note
            HStack(alignment: .top, spacing: Spacing.xs) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.secondaryAccent.opacity(0.6))
                    .frame(width: 16, height: 16)
                    .padding(.top, 2)

                Text("This isn't ideal, but it's your best option for today. Consider rescheduling if possible.")
                    .font(.pathwiseCaption)
                    .foregroundColor(.primaryText.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, Spacing.xs)
        }
    }

    // MARK: - Split Walk Content

    private func splitWalkContent(suggestion: SplitWalkSuggestion) -> some View {
        VStack(spacing: Spacing.md) {
            // Header
            HStack {
                Image(systemName: "figure.walk.circle.fill")
                    .font(.title3)
                    .foregroundColor(.accent)

                Text("Split Walk Suggestion")
                    .font(.pathwiseSubheadline)
                    .foregroundColor(.primaryText)

                Spacer()
            }

            // Info banner
            HStack(spacing: Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.secondaryAccent)
                    .font(.caption)

                Text("No single window fits, but you can split your walk!")
                    .font(.pathwiseCaption)
                    .foregroundColor(.primaryText.opacity(0.8))
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accent.opacity(0.1))
            .cornerRadius(CornerRadius.sm)

            Divider()

            // Total duration
            HStack {
                Text("Total: \(suggestion.totalDuration) minutes")
                    .font(.pathwiseHeadline)
                    .foregroundColor(.accent)
                Spacer()
                Text("Split into \(suggestion.windows.count) walks")
                    .font(.pathwiseBody)
                    .foregroundColor(.primaryText.opacity(0.7))
            }

            // Walk segments
            ForEach(Array(suggestion.windows.enumerated()), id: \.element.id) { index, window in
                VStack(spacing: Spacing.sm) {
                    HStack {
                        Text("Walk \(index + 1)")
                            .font(.pathwiseSubheadline)
                            .foregroundColor(.primaryText)
                        Spacer()
                    }

                    HStack(alignment: .center, spacing: Spacing.md) {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(window.timeString)
                                .font(.pathwiseHeadline)
                                .foregroundColor(.accent)

                            Text("\(window.durationInMinutes) min")
                                .font(.pathwiseBody)
                                .foregroundColor(.primaryText.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Weather
                        VStack(spacing: Spacing.xs) {
                            Image(systemName: window.weather.weatherCondition.sfSymbol)
                                .font(.system(size: 32, weight: .medium))
                                .foregroundColor(.secondaryAccent)

                            HStack(spacing: 4) {
                                Text("\(Int(window.weather.temperature))°F")
                                    .font(.pathwiseBody)
                                    .foregroundColor(.primaryText)

                                // UV Index indicator
                                if window.weather.uvIndex > 0 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "sun.max.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(uvIndexColor(window.weather.uvIndex))
                                        Text("\(window.weather.uvIndex)")
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(uvIndexColor(window.weather.uvIndex))
                                    }
                                    .padding(.horizontal, 3)
                                    .padding(.vertical, 2)
                                    .background(uvIndexColor(window.weather.uvIndex).opacity(0.15))
                                    .cornerRadius(3)
                                }
                            }
                        }
                    }
                }
                .padding(Spacing.md)
                .background(Color.primaryBackground.opacity(0.5))
                .cornerRadius(CornerRadius.md)
            }
        }
    }

    // MARK: - No Window Content

    private var noWindowContent: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: iconForNoWindowReason(noWindowReason))
                .font(.system(size: 44))
                .foregroundColor(.primaryText.opacity(0.3))

            Text("No Windows Available")
                .font(.pathwiseHeadline)
                .foregroundColor(.primaryText)

            if let reason = noWindowReason {
                // Show warning banner for weather-related issues
                if reason.severity != WeatherSeverity.none {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.secondaryAccent)
                            .font(.caption)

                        Text(reason.rawValue)
                            .font(.pathwiseCaption)
                            .foregroundColor(.primaryText.opacity(0.8))
                    }
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.secondaryAccent.opacity(0.1))
                    .cornerRadius(CornerRadius.sm)
                } else {
                    Text(reason.rawValue)
                        .font(.pathwiseBody)
                        .foregroundColor(.primaryText.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
            } else {
                Text("Your schedule is too packed or the weather isn't cooperating. Try again tomorrow!")
                    .font(.pathwiseBody)
                    .foregroundColor(.primaryText.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.lg)
    }

    // Helper to get appropriate icon for no-window reason
    private func iconForNoWindowReason(_ reason: NoWindowReason?) -> String {
        guard let reason = reason else {
            return "calendar.badge.exclamationmark"
        }

        switch reason {
        case .noFreeTime:
            return "calendar.badge.exclamationmark"
        case .unsafeWeather:
            return "cloud.bolt.rain.fill"
        case .poorWeather:
            return "cloud.rain.fill"
        case .scheduleTooTight:
            return "clock.badge.exclamationmark"
        case .noWeatherData:
            return "antenna.radiowaves.left.and.right.slash"
        }
    }

    // Helper to get color for UV index
    private func uvIndexColor(_ uvIndex: Int) -> Color {
        switch uvIndex {
        case 0...2:
            return .green
        case 3...5:
            return .yellow
        case 6...7:
            return .orange
        case 8...10:
            return .red
        default:
            return .purple
        }
    }
}

// MARK: - Window Details View

struct WindowDetailsView: View {
    let window: GoldenWindow
    var showWeatherWarning: Bool = false
    var weatherWarningText: String? = nil
    var uvIndexColor: (Int) -> Color

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Weather Warning Banner (if applicable)
            if showWeatherWarning, let warningText = weatherWarningText {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.secondaryAccent)
                        .font(.caption)

                    Text(warningText)
                        .font(.pathwiseCaption)
                        .foregroundColor(.primaryText.opacity(0.8))
                }
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondaryAccent.opacity(0.1))
                .cornerRadius(CornerRadius.sm)
            }

            // Time and Weather Display
            HStack(alignment: .center, spacing: Spacing.lg) {
                // Time section
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    if window.isContinuousWindow {
                        Text(window.timeRangeString)
                            .font(.pathwiseHeadline)
                            .foregroundColor(.accent)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Flexible timing available")
                            .font(.pathwiseBody)
                            .foregroundColor(.primaryText.opacity(0.7))
                    } else {
                        Text(window.timeString)
                            .font(.pathwiseLargeNumber)
                            .foregroundColor(.accent)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)

                        Text("\(window.durationInMinutes) minute walk")
                            .font(.pathwiseBody)
                            .foregroundColor(.primaryText.opacity(0.7))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Weather section
                VStack(spacing: Spacing.xs) {
                    Image(systemName: window.weather.weatherCondition.sfSymbol)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(.secondaryAccent)
                        .symbolRenderingMode(.hierarchical)

                    HStack(spacing: 4) {
                        Text("\(Int(window.weather.temperature))°F")
                            .font(.pathwiseHeadline)
                            .foregroundColor(.primaryText)

                        // UV Index indicator
                        if window.weather.uvIndex > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(uvIndexColor(window.weather.uvIndex))
                                Text("\(window.weather.uvIndex)")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(uvIndexColor(window.weather.uvIndex))
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(uvIndexColor(window.weather.uvIndex).opacity(0.15))
                            .cornerRadius(4)
                        }
                    }
                }
                .frame(width: 90)
            }

            Divider()
                .padding(.vertical, Spacing.xs)

            // Reason Summary
            HStack(alignment: .top, spacing: Spacing.sm) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.accent.opacity(0.6))
                    .font(.caption)

                Text(window.reasonSummary)
                    .font(.pathwiseBody)
                    .foregroundColor(.primaryText.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Location (if available)
            if let locationName = window.locationName {
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.accent.opacity(0.6))

                    Text(locationName)
                        .font(.pathwiseCaption)
                        .foregroundColor(.primaryText.opacity(0.6))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

// MARK: - Timeline View

struct TimelineView: View {
    let windows: [GoldenWindow]
    @Binding var currentIndex: Int

    var body: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(Array(windows.enumerated()), id: \.element.id) { index, window in
                TimelineSegment(
                    window: window,
                    isSelected: index == currentIndex,
                    position: Double(index) / Double(windows.count - 1)
                )
                .onTapGesture {
                    withAnimation {
                        currentIndex = index
                    }
                }
            }
        }
        .padding(.vertical, Spacing.sm)
    }
}

struct TimelineSegment: View {
    let window: GoldenWindow
    let isSelected: Bool
    let position: Double

    var body: some View {
        VStack(spacing: 4) {
            // Timeline dot
            Circle()
                .fill(isSelected ? Color.accent : Color.accent.opacity(0.3))
                .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                .frame(height: 12, alignment: .center) // Fixed height for alignment

            // Time label
            if isSelected {
                Text(window.timeString)
                    .font(.pathwiseCaption)
                    .foregroundColor(.accent)
                    .fontWeight(.semibold)
            } else {
                // Invisible placeholder to maintain consistent height
                Text(" ")
                    .font(.pathwiseCaption)
                    .opacity(0)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status)
            .font(.pathwiseCaption)
            .fontWeight(.semibold)
            .foregroundColor(.secondaryAccent)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Color.secondaryAccent.opacity(0.15))
            .cornerRadius(CornerRadius.sm)
    }
}

// MARK: - Previews

#Preview("Single Golden Window") {
    GoldenWindowCard(
        goldenWindows: [
            GoldenWindow(
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
            )
        ],
        fallbackWindow: nil,
        splitWalkSuggestion: nil,
        noWindowReason: nil
    )
    .padding()
    .background(Color.primaryBackground)
}

#Preview("Multiple Golden Windows") {
    GoldenWindowCard(
        goldenWindows: [
            GoldenWindow(
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
            ),
            GoldenWindow(
                startTime: Calendar.current.date(byAdding: .hour, value: 3, to: Date())!,
                endTime: Calendar.current.date(byAdding: .hour, value: 5, to: Date())!.addingTimeInterval(1800),
                score: 75.0,
                weather: HourlyWeather(
                    time: Calendar.current.date(byAdding: .hour, value: 3, to: Date())!,
                    temperature: 68,
                    precipitationProbability: 0.2,
                    uvIndex: 4,
                    weatherCondition: .partlyCloudy
                ),
                reasonSummary: "Great for a walk—68°F with flexible timing",
                locationName: "San Francisco, CA"
            ),
            GoldenWindow(
                startTime: Calendar.current.date(byAdding: .hour, value: 7, to: Date())!,
                endTime: Calendar.current.date(byAdding: .hour, value: 7, to: Date())!.addingTimeInterval(1200),
                score: 70.0,
                weather: HourlyWeather(
                    time: Calendar.current.date(byAdding: .hour, value: 7, to: Date())!,
                    temperature: 65,
                    precipitationProbability: 0.15,
                    uvIndex: 3,
                    weatherCondition: .partlyCloudy
                ),
                reasonSummary: "Good window—65°F",
                locationName: "San Francisco, CA"
            )
        ],
        fallbackWindow: nil,
        splitWalkSuggestion: nil,
        noWindowReason: nil
    )
    .padding()
    .background(Color.primaryBackground)
}

#Preview("Fallback Window") {
    GoldenWindowCard(
        goldenWindows: [],
        fallbackWindow: GoldenWindow(
            startTime: Date(),
            endTime: Date().addingTimeInterval(1200),
            score: 45.0,
            weather: HourlyWeather(
                time: Date(),
                temperature: 55,
                precipitationProbability: 0.35,
                uvIndex: 2,
                weatherCondition: .cloudy
            ),
            reasonSummary: "Best available—a bit chilly at 55°F, 35% chance of rain",
            locationName: "San Francisco, CA"
        ),
        splitWalkSuggestion: nil,
        noWindowReason: .unsafeWeather
    )
    .padding()
    .background(Color.primaryBackground)
}

#Preview("No Window") {
    GoldenWindowCard(
        goldenWindows: [],
        fallbackWindow: nil,
        splitWalkSuggestion: nil,
        noWindowReason: .noFreeTime
    )
    .padding()
    .background(Color.primaryBackground)
}
