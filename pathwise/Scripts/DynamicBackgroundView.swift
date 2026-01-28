import SwiftUI
import Foundation
import Combine

private struct DynamicForegroundColorKey: EnvironmentKey { static let defaultValue: Color = .primaryText }
extension EnvironmentValues { var dynamicForegroundColor: Color { get { self[DynamicForegroundColorKey.self] } set { self[DynamicForegroundColorKey.self] = newValue } } }

public struct DynamicBackgroundView: View {
    @State private var now: Date = Date()
    @AppStorage("dynamicBackgroundEnabled") private var dynamicEnabled: Bool = true
    @StateObject private var devSettings = DeveloperSettings.shared

    @State private var boundaries: DaylightBoundaries?
    @State private var lastColors: [Color]? = nil

    private let boundariesKey = "dynamicBackground.boundaries"

    private struct StoredBoundaries: Codable {
        let sunrise: Date
        let sunset: Date
        let civilDawnStart: Date
        let civilDuskEnd: Date
    }

    public init() {}

    public var body: some View {
        Group {
            if dynamicEnabled {
                let colors = mockedColorsIfAny() ?? gradientColorsLive(for: now)
                LinearGradient(gradient: Gradient(colors: colors), startPoint: .bottom, endPoint: .top)
                    .ignoresSafeArea()
                    .environment(\.dynamicForegroundColor, suggestedForeground(for: colors))
                    .onAppear {
                        self.boundaries = loadStoredBoundaries()
                        if devSettings.isEnabled {
                            if let b = boundaries {
                                print("[DynamicBackgroundView] Loaded stored boundaries: \(b)")
                            } else {
                                print("[DynamicBackgroundView] No stored boundaries found")
                            }
                        }
                        refreshBoundaries()
                        scheduleMidnightRefresh()
                    }
                    .onChange(of: now) { _, _ in
                        lastColors = colors
                    }
            } else {
                Color.primaryBackground
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.8), value: dynamicEnabled)
        .animation(.easeInOut(duration: 0.8), value: now)
    }

    // MARK: - Timer to update time smoothly
    private func startTimer() {
        // Update every 5 minutes for subtle transitions
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            now = Date()
        }
    }

    // MARK: - Refresh boundaries and schedule updates
    private func refreshBoundaries() {
        Task {
            let locationService = LocationService()
            await locationService.requestLocationPermission()
            await locationService.requestLocation()
            if let loc = locationService.currentLocation {
                let provider = SunriseSunsetProvider.shared
                let b = await provider.boundaries(for: loc, on: Date())
                await MainActor.run {
                    self.boundaries = b
                    if devSettings.isEnabled {
                        if let b {
                            print("[DynamicBackgroundView] Refreshed boundaries: sunrise=\(b.sunrise), sunset=\(b.sunset), civilDawnStart=\(b.civilDawnStart), civilDuskEnd=\(b.civilDuskEnd)")
                        } else {
                            print("[DynamicBackgroundView] Refreshed boundaries: nil")
                        }
                    }
                    if let b { saveStoredBoundaries(b) }
                    scheduleUpdates()
                }
            }
        }
    }

    private func scheduleUpdates() {
        if devSettings.isEnabled {
            print("[DynamicBackgroundView] Scheduling updates")
        }
        // periodic tick every 5 minutes
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in now = Date() }
        // schedule exact boundary ticks if boundaries available
        if let b = boundaries {
            let dates = [b.civilDawnStart, b.sunrise, b.sunset, b.civilDuskEnd]
            for d in dates where d > Date() {
                let interval = d.timeIntervalSinceNow
                Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { _ in now = Date() }
            }
        }
    }
    
    private func scheduleMidnightRefresh() {
        let cal = Calendar.current
        let startOfTomorrow = cal.startOfDay(for: Date()).addingTimeInterval(24 * 60 * 60)
        let interval = startOfTomorrow.timeIntervalSinceNow
        Timer.scheduledTimer(withTimeInterval: max(10, interval), repeats: false) { _ in
            refreshBoundaries()
            scheduleMidnightRefresh()
        }
    }

    // MARK: - Stored boundaries helpers
    private func loadStoredBoundaries() -> DaylightBoundaries? {
        guard let data = UserDefaults.standard.data(forKey: boundariesKey),
              let stored = try? JSONDecoder().decode(StoredBoundaries.self, from: data) else {
            return nil
        }
        return DaylightBoundaries(sunrise: stored.sunrise, sunset: stored.sunset, civilDawnStart: stored.civilDawnStart, civilDuskEnd: stored.civilDuskEnd)
    }
    private func saveStoredBoundaries(_ b: DaylightBoundaries) {
        let stored = StoredBoundaries(sunrise: b.sunrise, sunset: b.sunset, civilDawnStart: b.civilDawnStart, civilDuskEnd: b.civilDuskEnd)
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: boundariesKey)
            if devSettings.isEnabled {
                print("[DynamicBackgroundView] Saved boundaries to UserDefaults")
            }
        }
    }

    // MARK: - Gradient Logic
    private func gradientColors(for date: Date) -> [Color] {
        // Simple heuristic sunrise/sunset estimates; can be replaced with actual location-based times later
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let dayMinutes = hour * 60 + minute

        // Define phases (in minutes). Dawn 5:30-7:30, Day 7:30-17:30, Sunset 17:30-19:30, Night otherwise
        let dawnStart = 5 * 60 + 30
        let dawnEnd = 7 * 60 + 30
        let dayEnd = 17 * 60 + 30
        let sunsetEnd = 19 * 60 + 30

        if dayMinutes >= dawnStart && dayMinutes < dawnEnd {
            return dawnGradient(progress: progress(in: dayMinutes, start: dawnStart, end: dawnEnd))
        } else if dayMinutes >= dawnEnd && dayMinutes < dayEnd {
            return dayGradient(progress: progress(in: dayMinutes, start: dawnEnd, end: dayEnd))
        } else if dayMinutes >= dayEnd && dayMinutes < sunsetEnd {
            return sunsetGradient(progress: progress(in: dayMinutes, start: dayEnd, end: sunsetEnd))
        } else {
            return nightGradient()
        }
    }

    private func gradientColorsLive(for date: Date) -> [Color] {
        guard let b = boundaries else { return gradientColors(for: date) }
        let now = date
        if now < b.civilDawnStart || now >= b.civilDuskEnd {
            return nightGradient()
        }
        if now >= b.civilDawnStart && now < b.sunrise {
            // Dawn early -> late mapping
            let total = b.sunrise.timeIntervalSince(b.civilDawnStart)
            let progress = max(0, min(1, now.timeIntervalSince(b.civilDawnStart) / total))
            return dawnGradient(progress: progress)
        }
        if now >= b.sunrise && now < b.sunset {
            // Day early/mid/late (split into thirds)
            let total = b.sunset.timeIntervalSince(b.sunrise)
            let p = max(0, min(1, now.timeIntervalSince(b.sunrise) / total))
            return dayGradient(progress: p)
        }
        // Sunset: from sunset to civilDuskEnd
        let total = b.civilDuskEnd.timeIntervalSince(b.sunset)
        let progress = max(0, min(1, now.timeIntervalSince(b.sunset) / total))
        return sunsetGradient(progress: progress)
    }

    private func progress(in value: Int, start: Int, end: Int) -> Double {
        guard end > start else { return 0 }
        return Double(value - start) / Double(end - start)
    }

    private func mockedColorsIfAny() -> [Color]? {
        switch devSettings.backgroundMock {
        case .system:
            return nil

        // Dawn variants with stronger separation
        case .dawnEarly:
            // Richer orange at horizon to deeper blue zenith
            return [
                Color.sunriseOrange.opacity(0.8),
                Color.skyBlueAccent.opacity(0.35),
                Color.deepOcean.opacity(0.95)
            ]
        case .dawnLate:
            // Warmer horizon but lighter top than early
            return [
                Color.sunriseOrange.opacity(0.55),
                Color.skyBlueAccent.opacity(0.35),
                Color.deepOcean.opacity(0.75)
            ]

        // Day variants with clearer separation
        case .dayEarly:
            // Cooler morning sky, more blue at top
            return [
                Color.cloudWhite,
                Color.skyBlue.opacity(0.28),
                Color.skyBlueAccent.opacity(0.30)
            ]
        case .dayMid:
            // Bright midday with light, airy blues
            return [
                Color.cloudWhite,
                Color.skyBlue.opacity(0.35),
                Color.skyBlueAccent.opacity(0.22)
            ]
        case .dayLate:
            // Late afternoon: slightly warmer horizon and deeper top
            return [
                Color.cloudWhite.opacity(0.95),
                Color.skyBlue.opacity(0.22),
                Color.skyBlueAccent.opacity(0.38)
            ]

        // Sunset variants with darker tones for late
        case .sunsetEarly:
            return [
                Color(hex: "#F2A7B3").opacity(0.6),
                Color.periwinkle.opacity(0.5),
                Color.deepPeriwinkle.opacity(0.85)
            ]
        case .sunsetLate:
            // Darker, moodier late sunset
            return [
                Color(hex: "#E07A8C").opacity(0.75), // deeper pink/red
                Color.periwinkle.opacity(0.55),
                Color.deepPeriwinkle.opacity(0.95)
            ]

        // Night
        case .night:
            return [Color.darkBackground, Color.darkBackgroundGradientTop]
        }
    }

    // MARK: - Suggested Foreground Color for Contrast
    private func suggestedForeground(for colors: [Color]) -> Color {
        // Sample top color to decide contrast; darker backgrounds -> light text, lighter -> dark text
        // Fallback to primaryText
        let useLight = isDarkBackground(colors: colors)
        return useLight ? Color.white.opacity(0.92) : Color.primaryText
    }

    private func isDarkBackground(colors: [Color]) -> Bool {
        // Heuristic: treat as dark if the top color appears dark from known palette
        // We check against our dark palette and deep blues
        let darkRefs: [Color] = [Color.darkBackground, Color.darkBackgroundGradientTop, Color.deepOcean, Color.deepPeriwinkle]
        // If any of the last (top) two colors match our dark references or if we are in night mock, consider dark
        return colors.suffix(2).contains { color in
            // Compare by description string as a lightweight heuristic
            String(describing: color) == String(describing: Color.darkBackground) ||
            String(describing: color) == String(describing: Color.darkBackgroundGradientTop) ||
            String(describing: color) == String(describing: Color.deepOcean) ||
            String(describing: color) == String(describing: Color.deepPeriwinkle)
        }
    }

    // MARK: - Phase Gradients using DesignSystem palette
    private func dawnGradient(progress: Double) -> [Color] {
        // Early dawn: deeper blue at top, subtle warm at bottom; late dawn transitions to current scheme
        let earlyFactor = 1 - progress // 1 at start, 0 at end
        let bottom = Color.sunriseOrange.opacity(0.35 + 0.35 * progress)
        let mid = Color.skyBlueAccent.opacity(0.25 + 0.15 * progress)
        let top = Color.deepOcean.opacity(0.75 + 0.15 * earlyFactor)
        return [bottom, mid, top]
    }

    private func dayGradient(progress: Double) -> [Color] {
        // Sky-like gradient: pale near horizon, light blue mid, slightly deeper zenith around midday
        // Create a subtle 3-color gradient
        let horizon = Color.cloudWhite
        let midSky = Color.skyBlue.opacity(0.25 + 0.15 * sin(progress * .pi))
        let zenith = Color.skyBlueAccent.opacity(0.20 + 0.10 * sin(progress * .pi))
        return [horizon, midSky, zenith]
    }

    private func sunsetGradient(progress: Double) -> [Color] {
        // Early sunset: deeper purples; later: warmer pink/orange closer to horizon
        let bottom = Color(hex: "#F2A7B3").opacity(0.55 + 0.20 * progress) // pink warms as it gets later
        let mid = Color.periwinkle.opacity(0.35 + 0.20 * (1 - progress))
        let top = Color.deepPeriwinkle.opacity(0.80 + 0.10 * (1 - progress))
        return [bottom, mid, top]
    }

    private func nightGradient() -> [Color] {
        // Respect existing dark mode palette
        return [Color.darkBackground, Color.darkBackgroundGradientTop]
    }
}

// Preview
#Preview {
    ZStack {
        DynamicBackgroundView()
        VStack {
            Text("Dynamic Background Preview")
                .font(.headline)
                .foregroundColor(.primaryText)
        }
        .padding()
    }
}

