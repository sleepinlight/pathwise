//
//  GoldenWindow.swift
//  pathwise
//
//  The Golden Window model and scoring system
//

import Foundation

struct GoldenWindow: Identifiable, Codable {
    let id = UUID()
    let startTime: Date
    let endTime: Date
    let score: Double
    let weather: HourlyWeather
    let reasonSummary: String
    let locationName: String?

    enum CodingKeys: String, CodingKey {
        case startTime, endTime, score, weather, reasonSummary, locationName
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: startTime)
    }

    var durationInMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }

    func isActiveNow() -> Bool {
        let now = Date()
        return now >= startTime && now <= endTime
    }

    func isUpcoming() -> Bool {
        return startTime > Date()
    }

    func isPast() -> Bool {
        return endTime < Date()
    }

    var statusDescription: String {
        if isActiveNow() {
            return "Now"
        } else if isUpcoming() {
            let minutes = Int(startTime.timeIntervalSince(Date()) / 60)
            if minutes < 60 {
                return "in \(minutes)m"
            } else {
                let hours = minutes / 60
                return "in \(hours)h"
            }
        } else {
            return "Past"
        }
    }
}

enum AppTheme: String, Codable, CaseIterable {
    case light = "Light"
    case dark = "Dark"
    case system = "System"
}

enum DarkModeStyle: String, Codable, CaseIterable {
    case `default` = "Default"
    case black = "Black"
}

struct UserPreferences: Codable {
    var preferredWalkDuration: Int = 20 // minutes
    var idealTemperatureMin: Double = 60 // Fahrenheit
    var idealTemperatureMax: Double = 80 // Fahrenheit
    var extremeTempMin: Double = 30 // Fahrenheit
    var extremeTempMax: Double = 90 // Fahrenheit
    var dailyStepGoal: Int = 8000
    var morningNotificationTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 30))!
    var theme: AppTheme = .system
    var darkModeStyle: DarkModeStyle = .default
    var preferredWalkStartTime: Date = Calendar.current.date(from: DateComponents(hour: 6, minute: 0))!  // 6:00 AM default
    var preferredWalkEndTime: Date = Calendar.current.date(from: DateComponents(hour: 20, minute: 0))!   // 8:00 PM default

    func isTemperatureIdeal(_ temp: Double) -> Bool {
        temp >= idealTemperatureMin && temp <= idealTemperatureMax
    }

    func isTemperatureExtreme(_ temp: Double) -> Bool {
        temp < extremeTempMin || temp > extremeTempMax
    }
}
