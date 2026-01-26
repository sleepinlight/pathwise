import Foundation
import CoreLocation
import WeatherKit

struct DaylightBoundaries {
    let sunrise: Date
    let sunset: Date
    let civilDawnStart: Date // start of civil twilight in the morning
    let civilDuskEnd: Date   // end of civil twilight in the evening
}

actor SunriseSunsetProvider {

    static let shared = SunriseSunsetProvider()

    func boundaries(for location: CLLocation, on date: Date) async -> DaylightBoundaries? {
        // Try WeatherKit daily forecast first
        do {
            let weather = try await WeatherKit.WeatherService.shared.weather(for: location)
            if let day = weather.dailyForecast.forecast.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) }) {
                if let sunrise = day.sun.sunrise, let sunset = day.sun.sunset {
                    // Civil twilight not available in this WeatherKit version — approximate at ±30 minutes
                    let civilDawn = sunrise.addingTimeInterval(-1800)
                    let civilDusk = sunset.addingTimeInterval(1800)
                    return DaylightBoundaries(sunrise: sunrise, sunset: sunset, civilDawnStart: civilDawn, civilDuskEnd: civilDusk)
                }
            }
        } catch {
            // fall through to solar fallback
        }
        // Fallback: simple civil twilight approximation (30 minutes before/after sunrise/sunset) using a naive sunrise/sunset estimation
        guard let naive = naiveSunTimes(for: location, on: date) else { return nil }
        let sunrise = naive.sunrise
        let sunset = naive.sunset
        let civilDawn = sunrise.addingTimeInterval(-1800)
        let civilDusk = sunset.addingTimeInterval(1800)
        return DaylightBoundaries(sunrise: sunrise, sunset: sunset, civilDawnStart: civilDawn, civilDuskEnd: civilDusk)
    }

    // MARK: - Naive sunrise/sunset fallback (very rough; adequate as a last resort)
    private func naiveSunTimes(for location: CLLocation, on date: Date) -> (sunrise: Date, sunset: Date)? {
        // Use a very rough heuristic based on timezone and latitude: sunrise ~ 6:30, sunset ~ 18:30 local
        // Adjust a bit by latitude so higher latitudes shift more across seasons (simple sine mod)
        let calendar = Calendar.current
        let longitude = location.coordinate.longitude
        let latitude = location.coordinate.latitude

        // Calculate timezone offset in seconds based on longitude
        let timeZoneSeconds = Int(longitude / 15.0 * 3600)
        guard let tz = TimeZone(secondsFromGMT: timeZoneSeconds) ?? calendar.timeZone as TimeZone? else { return nil }

        // Calculate day of year (1...366)
        guard let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) else { return nil }

        // Simple seasonal variation factor (-1 to 1)
        let seasonalVariation = sin((Double(dayOfYear) / 365.0) * 2 * Double.pi)

        // Latitude factor (-1 to 1)
        let latFactor = latitude / 90.0

        // Calculate sunrise time offset in seconds (-1800 to 1800) to add/subtract from base 6:30 and 18:30
        let offsetSeconds = Int(1800 * seasonalVariation * latFactor)

        var comps = calendar.dateComponents(in: tz, from: date)
        comps.hour = 6
        comps.minute = 30
        comps.second = 0
        guard let baseSunrise = calendar.date(from: comps) else { return nil }
        let sunriseLocal = baseSunrise.addingTimeInterval(TimeInterval(-offsetSeconds))

        comps.hour = 18
        comps.minute = 30
        comps.second = 0
        guard let baseSunset = calendar.date(from: comps) else { return nil }
        let sunsetLocal = baseSunset.addingTimeInterval(TimeInterval(offsetSeconds))

        return (sunriseLocal, sunsetLocal)
    }
}

