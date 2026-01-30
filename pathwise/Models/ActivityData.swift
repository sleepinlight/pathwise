//
//  ActivityData.swift
//  pathwise
//
//  Activity and health tracking models
//

import Foundation
import HealthKit

struct DailyActivity: Identifiable, Codable {
    let id = UUID()
    let date: Date
    var steps: Int
    var distance: Double // miles
    var minutesMoved: Int
    var claimedWindow: Bool // Did the user walk during their Golden Window?

    enum CodingKeys: String, CodingKey {
        case date, steps, distance, minutesMoved, claimedWindow
    }
}

struct WeeklyActivitySummary: Identifiable {
    let id = UUID()
    let weekStartDate: Date
    let dailyActivities: [DailyActivity]

    var totalSteps: Int {
        dailyActivities.reduce(0) { $0 + $1.steps }
    }

    var totalDistance: Double {
        dailyActivities.reduce(0) { $0 + $1.distance }
    }

    var windowsClaimedCount: Int {
        dailyActivities.filter { $0.claimedWindow }.count
    }

    var averageSteps: Int {
        guard !dailyActivities.isEmpty else { return 0 }
        return totalSteps / dailyActivities.count
    }
}

struct WorkoutSummary: Identifiable {
    let id = UUID()
    let type: HKWorkoutActivityType
    let startDate: Date
    let endDate: Date
    let duration: TimeInterval // in seconds
    let distance: Double // miles
    let isOutdoor: Bool

    var durationInMinutes: Int {
        Int(duration / 60)
    }

    var activityName: String {
        switch type {
        case .walking:
            return isOutdoor ? "Outdoor Walk" : "Indoor Walk"
        case .running:
            return isOutdoor ? "Outdoor Run" : "Indoor Run"
        default:
            return "Workout"
        }
    }
}
