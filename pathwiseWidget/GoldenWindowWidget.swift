//
//  GoldenWindowWidget.swift
//  pathwise
//
//  Golden Window Widget - Shows next golden window and activity progress
//

import WidgetKit
import SwiftUI

// MARK: - Widget Entry

struct GoldenWindowEntry: TimelineEntry {
    let date: Date
    let goldenWindow: GoldenWindow?
    let additionalWindows: [GoldenWindow]
    let fallbackWindow: GoldenWindow?
    let noWindowReason: NoWindowReason?
    let todaySteps: Int
    let stepGoal: Int
    let isInGoldenWindow: Bool
    let theme: AppTheme
    let darkModeStyle: DarkModeStyle
}

// MARK: - Widget Provider

struct GoldenWindowProvider: TimelineProvider {
    func placeholder(in context: Context) -> GoldenWindowEntry {
        let preferences = UserPreferences()
        return GoldenWindowEntry(
            date: Date(),
            goldenWindow: createSampleWindow(),
            additionalWindows: [],
            fallbackWindow: nil,
            noWindowReason: nil,
            todaySteps: 3500,
            stepGoal: preferences.dailyStepGoal,
            isInGoldenWindow: false,
            theme: .system,
            darkModeStyle: .default
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (GoldenWindowEntry) -> Void) {
        let preferences = UserPreferences()
        let entry = GoldenWindowEntry(
            date: Date(),
            goldenWindow: createSampleWindow(),
            additionalWindows: [],
            fallbackWindow: nil,
            noWindowReason: nil,
            todaySteps: 3500,
            stepGoal: preferences.dailyStepGoal,
            isInGoldenWindow: false,
            theme: .system,
            darkModeStyle: .default
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<GoldenWindowEntry>) -> Void) {
        let currentDate = Date()

        // Try to load data from shared App Group
        let widgetData = PathwiseWidgetDataManager.shared.loadPathwiseWidgetData()

        let entry: GoldenWindowEntry
        if let data = widgetData {
            // Use real data from the main app
            entry = GoldenWindowEntry(
                date: currentDate,
                goldenWindow: data.goldenWindow,
                additionalWindows: data.additionalWindows,
                fallbackWindow: data.fallbackWindow,
                noWindowReason: data.noWindowReason,
                todaySteps: data.todaySteps,
                stepGoal: data.stepGoal,
                isInGoldenWindow: data.isInGoldenWindow,
                theme: data.theme,
                darkModeStyle: data.darkModeStyle
            )
        } else {
            // Fallback to sample data if no shared data available
            let window = createSampleWindow()
            let preferences = UserPreferences()
            entry = GoldenWindowEntry(
                date: currentDate,
                goldenWindow: window,
                additionalWindows: [],
                fallbackWindow: nil,
                noWindowReason: nil,
                todaySteps: 3500,
                stepGoal: preferences.dailyStepGoal,
                isInGoldenWindow: false,
                theme: .system,
                darkModeStyle: .default
            )
        }

        // Refresh every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createSampleWindow() -> GoldenWindow {
        let now = Date()
        let calendar = Calendar.current
        return GoldenWindow(
            startTime: calendar.date(byAdding: .hour, value: 2, to: now)!,
            endTime: calendar.date(byAdding: .minute, value: 140, to: now)!,
            score: 85.0,
            weather: HourlyWeather(
                time: calendar.date(byAdding: .hour, value: 2, to: now)!,
                temperature: 72,
                precipitationProbability: 0.1,
                uvIndex: 4,
                weatherCondition: .clear
            ),
            reasonSummary: "Perfect conditions—72°F",
            locationName: nil
        )
    }
}

// MARK: - Small Widget View

struct SmallGoldenWindowView: View {
    let entry: GoldenWindowEntry
    @Environment(\.colorScheme) var systemColorScheme

    private var effectiveColorScheme: ColorScheme {
        switch entry.theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return systemColorScheme
        }
    }

    private var backgroundColor: Color {
        if effectiveColorScheme == .dark {
            return entry.darkModeStyle == .black ? .black : Color(red: 0.11, green: 0.11, blue: 0.12)
        } else {
            return Color(red: 0.98, green: 0.98, blue: 0.99)
        }
    }

    private var displayWindow: GoldenWindow? {
        entry.goldenWindow ?? entry.fallbackWindow
    }

    var body: some View {
        ZStack {
            Color.clear

            if let window = displayWindow {
                VStack(spacing: 8) {
                    // Header
                    HStack {
                        Image(systemName: entry.isInGoldenWindow ? "sparkles.rectangle.stack.fill" : "sparkles")
                            .font(.caption)
                            .foregroundColor(.accent)

                        Text(entry.isInGoldenWindow ? "Let's Walk" : "Next Window")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(effectiveColorScheme == .dark ? .white.opacity(0.9) : .primaryText.opacity(0.7))

                        Spacer()
                    }

                    Spacer()

                    // Time
                    if entry.isInGoldenWindow {
                        Text("Now")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.accent)
                    } else {
                        VStack(spacing: 2) {
                            Text("Starts at")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(effectiveColorScheme == .dark ? .white.opacity(0.7) : .primaryText.opacity(0.6))
                            Text(window.timeString)
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.accent)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                        }
                    }

                    // Weather info
                    HStack(spacing: 6) {
                        Image(systemName: window.weather.weatherCondition.sfSymbol)
                            .font(.title3)
                            .foregroundColor(.secondaryAccent)

                        Text("\(Int(window.weather.temperature))°F")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(effectiveColorScheme == .dark ? .white : .primaryText)

                        if window.weather.uvIndex > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: "sun.max.fill")
                                    .font(.system(size: 8))
                                Text("\(window.weather.uvIndex)")
                                    .font(.system(size: 9, weight: .medium))
                            }
                            .foregroundColor(uvIndexColor(window.weather.uvIndex))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(uvIndexColor(window.weather.uvIndex).opacity(0.15))
                            .cornerRadius(3)
                        }
                    }

                    Spacer()
                }
                .padding(12)
            } else if let reason = entry.noWindowReason {
                // No window with reason
                VStack(spacing: 8) {
                    Image(systemName: noWindowIcon(for: reason))
                        .font(.largeTitle)
                        .foregroundColor(noWindowColor(for: reason))

                    Text(noWindowTitle(for: reason))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(12)
            } else {
                // No window available
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.primaryText.opacity(0.3))

                    Text("No Windows")
                        .font(.caption)
                        .foregroundColor(.primaryText.opacity(0.6))
                }
            }
        }
        .preferredColorScheme(effectiveColorScheme)
    }

    private func noWindowIcon(for reason: NoWindowReason) -> String {
        switch reason {
        case .noFreeTime:
            return "calendar.badge.clock"
        case .unsafeWeather:
            return "exclamationmark.triangle.fill"
        case .poorWeather:
            return "cloud.drizzle.fill"
        case .scheduleTooTight:
            return "clock.badge.exclamationmark"
        case .noWeatherData:
            return "wifi.slash"
        }
    }

    private func noWindowColor(for reason: NoWindowReason) -> Color {
        switch reason {
        case .unsafeWeather:
            return .orange
        case .noFreeTime, .scheduleTooTight:
            return .blue
        case .poorWeather, .noWeatherData:
            return .gray
        }
    }

    private func noWindowTitle(for reason: NoWindowReason) -> String {
        switch reason {
        case .noFreeTime:
            return "Fully Booked"
        case .unsafeWeather:
            return "Unsafe Weather"
        case .poorWeather:
            return "Poor Weather"
        case .scheduleTooTight:
            return "No Time Slots"
        case .noWeatherData:
            return "No Weather Data"
        }
    }

    private func uvIndexColor(_ uvIndex: Int) -> Color {
        switch uvIndex {
        case 0...2: return .green
        case 3...5: return .yellow
        case 6...7: return .orange
        case 8...10: return .red
        default: return .purple
        }
    }
}

// MARK: - Medium Widget View

struct MediumGoldenWindowView: View {
    let entry: GoldenWindowEntry
    @Environment(\.colorScheme) var systemColorScheme

    private var effectiveColorScheme: ColorScheme {
        switch entry.theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return systemColorScheme
        }
    }

    private var backgroundColor: Color {
        if effectiveColorScheme == .dark {
            return entry.darkModeStyle == .black ? .black : Color(red: 0.11, green: 0.11, blue: 0.12)
        } else {
            return Color(red: 0.98, green: 0.98, blue: 0.99)
        }
    }

    private var displayWindow: GoldenWindow? {
        entry.goldenWindow ?? entry.fallbackWindow
    }

    var body: some View {
        ZStack {
            Color.clear

            if let window = displayWindow {
                HStack(spacing: 16) {
                    // Left side: Window info
                    VStack(alignment: .leading, spacing: 8) {
                        // Header
                        HStack(spacing: 4) {
                            Image(systemName: entry.isInGoldenWindow ? "sparkles.rectangle.stack.fill" : "sparkles")
                                .font(.caption)
                                .foregroundColor(.accent)

                            Text(entry.isInGoldenWindow ? "Let's Walk" : "Next Window")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(effectiveColorScheme == .dark ? .white.opacity(0.9) : .primaryText.opacity(0.7))
                        }

                        Spacer()

                        // Time
                        if entry.isInGoldenWindow {
                            Text("Now")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.accent)
                        } else {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Starts at")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(effectiveColorScheme == .dark ? .white.opacity(0.7) : .primaryText.opacity(0.6))
                                Text(window.timeString)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.accent)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            }
                        }

                        // Weather
                        HStack(spacing: 8) {
                            Image(systemName: window.weather.weatherCondition.sfSymbol)
                                .font(.title2)
                                .foregroundColor(.secondaryAccent)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(Int(window.weather.temperature))°F")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(effectiveColorScheme == .dark ? .white : .primaryText)

                                if window.weather.uvIndex > 0 {
                                    HStack(spacing: 2) {
                                        Image(systemName: "sun.max.fill")
                                            .font(.system(size: 8))
                                        Text("UV \(window.weather.uvIndex)")
                                            .font(.system(size: 9, weight: .medium))
                                    }
                                    .foregroundColor(uvIndexColor(window.weather.uvIndex))
                                }
                            }
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    // Right side: Progress
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Today's Progress")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(effectiveColorScheme == .dark ? .white.opacity(0.9) : .primaryText.opacity(0.7))

                        Spacer()

                        // Steps progress
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .font(.caption)
                                    .foregroundColor(.secondaryAccent)

                                Text("\(entry.todaySteps)")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(effectiveColorScheme == .dark ? .white : .primaryText)

                                Spacer()
                            }

                            Text("of \(entry.stepGoal) steps")
                                .font(.caption)
                                .foregroundColor(effectiveColorScheme == .dark ? .white.opacity(0.7) : .primaryText.opacity(0.6))

                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.accent.opacity(0.15))
                                        .frame(height: 6)

                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.accent)
                                        .frame(
                                            width: geometry.size.width * min(Double(entry.todaySteps) / Double(entry.stepGoal), 1.0),
                                            height: 6
                                        )
                                }
                            }
                            .frame(height: 6)
                        }

                        Spacer()

                        // Mini timeline if continuous or multiple windows
                        if window.isContinuousWindow || !entry.additionalWindows.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Timeline")
                                    .font(.caption2)
                                    .foregroundColor(.primaryText.opacity(0.7))

                                HStack(spacing: 2) {
                                    ForEach(0..<3, id: \.self) { index in
                                        if index == 0 || index < entry.additionalWindows.count + 1 {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(index == 0 ? Color.accent : Color.accent.opacity(0.4))
                                                .frame(height: 4)
                                        } else {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.primaryText.opacity(0.1))
                                                .frame(height: 4)
                                        }
                                    }
                                }
                            }
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(12)
            } else if let reason = entry.noWindowReason {
                // No window with reason
                HStack(spacing: 16) {
                    // Left: Icon and reason
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: noWindowIcon(for: reason))
                            .font(.title)
                            .foregroundColor(noWindowColor(for: reason))

                        Text(noWindowTitle(for: reason))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(effectiveColorScheme == .dark ? .white : .primaryText)

                        Text(reason.rawValue)
                            .font(.caption)
                            .foregroundColor(effectiveColorScheme == .dark ? .white.opacity(0.7) : .primaryText.opacity(0.6))
                            .lineLimit(2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Divider()

                    // Right: Progress
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Today")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(effectiveColorScheme == .dark ? .white.opacity(0.9) : .primaryText.opacity(0.7))

                        Text("\(entry.todaySteps)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(effectiveColorScheme == .dark ? .white : .primaryText)

                        Text("steps")
                            .font(.caption)
                            .foregroundColor(effectiveColorScheme == .dark ? .white.opacity(0.7) : .primaryText.opacity(0.6))

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accent.opacity(0.15))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accent)
                                    .frame(
                                        width: geometry.size.width * min(Double(entry.todaySteps) / Double(entry.stepGoal), 1.0),
                                        height: 6
                                    )
                            }
                        }
                        .frame(height: 6)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(12)
            } else {
                // No window available
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.primaryText.opacity(0.3))

                    Text("No Golden Windows")
                        .font(.subheadline)
                        .foregroundColor(.primaryText.opacity(0.6))

                    // Show progress anyway
                    VStack(spacing: 4) {
                        Text("\(entry.todaySteps) steps today")
                            .font(.caption)
                            .foregroundColor(.primaryText.opacity(0.7))

                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accent.opacity(0.15))
                                    .frame(height: 6)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accent)
                                    .frame(
                                        width: geometry.size.width * min(Double(entry.todaySteps) / Double(entry.stepGoal), 1.0),
                                        height: 6
                                    )
                            }
                        }
                        .frame(height: 6)
                    }
                    .frame(maxWidth: 120)
                }
                .padding()
            }
        }
        .preferredColorScheme(effectiveColorScheme)
    }

    private func noWindowIcon(for reason: NoWindowReason) -> String {
        switch reason {
        case .noFreeTime:
            return "calendar.badge.clock"
        case .unsafeWeather:
            return "exclamationmark.triangle.fill"
        case .poorWeather:
            return "cloud.drizzle.fill"
        case .scheduleTooTight:
            return "clock.badge.exclamationmark"
        case .noWeatherData:
            return "wifi.slash"
        }
    }

    private func noWindowColor(for reason: NoWindowReason) -> Color {
        switch reason {
        case .unsafeWeather:
            return .orange
        case .noFreeTime, .scheduleTooTight:
            return .blue
        case .poorWeather, .noWeatherData:
            return .gray
        }
    }

    private func noWindowTitle(for reason: NoWindowReason) -> String {
        switch reason {
        case .noFreeTime:
            return "Fully Booked"
        case .unsafeWeather:
            return "Unsafe Weather"
        case .poorWeather:
            return "Poor Weather"
        case .scheduleTooTight:
            return "No Time Slots"
        case .noWeatherData:
            return "No Weather Data"
        }
    }

    private func uvIndexColor(_ uvIndex: Int) -> Color {
        switch uvIndex {
        case 0...2: return .green
        case 3...5: return .yellow
        case 6...7: return .orange
        case 8...10: return .red
        default: return .purple
        }
    }
}

// MARK: - Widget Configuration

struct GoldenWindowWidget: Widget {
    let kind: String = "GoldenWindowWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GoldenWindowProvider()) { entry in
            GoldenWindowWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Golden Window")
        .description("See your next perfect walking window and today's progress.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct GoldenWindowWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var systemColorScheme
    let entry: GoldenWindowEntry

    private var effectiveColorScheme: ColorScheme {
        switch entry.theme {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return systemColorScheme
        }
    }

    private var backgroundColor: Color {
        if effectiveColorScheme == .dark {
            return entry.darkModeStyle == .black ? .black : Color(red: 0.11, green: 0.11, blue: 0.12)
        } else {
            return Color(red: 0.98, green: 0.98, blue: 0.99)
        }
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallGoldenWindowView(entry: entry)
            case .systemMedium:
                MediumGoldenWindowView(entry: entry)
            default:
                SmallGoldenWindowView(entry: entry)
            }
        }
        .containerBackground(for: .widget) {
            backgroundColor
        }
    }
}

// MARK: - Preview

#Preview("Small", as: .systemSmall) {
    GoldenWindowWidget()
} timeline: {
    GoldenWindowEntry(
        date: Date(),
        goldenWindow: GoldenWindow(
            startTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date())!,
            endTime: Calendar.current.date(byAdding: .minute, value: 140, to: Date())!,
            score: 85.0,
            weather: HourlyWeather(
                time: Date(),
                temperature: 72,
                precipitationProbability: 0.1,
                uvIndex: 4,
                weatherCondition: .clear
            ),
            reasonSummary: "Perfect conditions",
            locationName: nil
        ),
        additionalWindows: [],
        fallbackWindow: nil,
        noWindowReason: nil,
        todaySteps: 3500,
        stepGoal: UserPreferences().dailyStepGoal,
        isInGoldenWindow: false,
        theme: .system,
        darkModeStyle: .default
    )
}

#Preview("Medium", as: .systemMedium) {
    GoldenWindowWidget()
} timeline: {
    GoldenWindowEntry(
        date: Date(),
        goldenWindow: GoldenWindow(
            startTime: Calendar.current.date(byAdding: .hour, value: 2, to: Date())!,
            endTime: Calendar.current.date(byAdding: .minute, value: 140, to: Date())!,
            score: 85.0,
            weather: HourlyWeather(
                time: Date(),
                temperature: 72,
                precipitationProbability: 0.1,
                uvIndex: 4,
                weatherCondition: .clear
            ),
            reasonSummary: "Perfect conditions",
            locationName: nil
        ),
        additionalWindows: [],
        fallbackWindow: nil,
        noWindowReason: nil,
        todaySteps: 5432,
        stepGoal: UserPreferences().dailyStepGoal,
        isInGoldenWindow: false,
        theme: .system,
        darkModeStyle: .default
    )
}
