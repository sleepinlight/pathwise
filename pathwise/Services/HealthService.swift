//
//  HealthService.swift
//  pathwise
//
//  HealthKit integration for step tracking and activity data
//

import Foundation
import HealthKit
import Combine

class HealthService: ObservableObject {
    private let healthStore = HKHealthStore()

    @Published var hasHealthAccess = false
    @Published var todaySteps: Int = 0
    @Published var todayDistance: Double = 0.0
    @Published var todayMinutesMoved: Int = 0
    @Published var weeklyActivities: [DailyActivity] = []

    private let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    private let exerciseTimeType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!

    // MARK: - Authorization
    func requestHealthAccess() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }

        let typesToRead: Set<HKObjectType> = [
            stepCountType,
            distanceType,
            exerciseTimeType
        ]

        do {
            try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
            await MainActor.run {
                self.hasHealthAccess = true
            }
            return true
        } catch {
            print("HealthKit authorization error: \(error)")
            return false
        }
    }

    // MARK: - Fetch Today's Data
    func fetchTodayActivity() async {
        guard hasHealthAccess else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let now = Date()

        async let steps = fetchSteps(from: startOfDay, to: now)
        async let distance = fetchDistance(from: startOfDay, to: now)
        async let minutes = fetchExerciseMinutes(from: startOfDay, to: now)

        let (stepsValue, distanceValue, minutesValue) = await (steps, distance, minutes)

        await MainActor.run {
            self.todaySteps = stepsValue
            self.todayDistance = distanceValue
            self.todayMinutesMoved = minutesValue
        }
    }

    // MARK: - Fetch Weekly Data
    func fetchWeeklyActivity() async {
        guard hasHealthAccess else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var dailyActivities: [DailyActivity] = []

        for dayOffset in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: today)!
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            async let steps = fetchSteps(from: startOfDay, to: endOfDay)
            async let distance = fetchDistance(from: startOfDay, to: endOfDay)
            async let minutes = fetchExerciseMinutes(from: startOfDay, to: endOfDay)

            let (stepsValue, distanceValue, minutesValue) = await (steps, distance, minutes)

            let activity = DailyActivity(
                date: startOfDay,
                steps: stepsValue,
                distance: distanceValue,
                minutesMoved: minutesValue,
                claimedWindow: false // Will be updated based on walk tracking
            )
            dailyActivities.append(activity)
        }

        await MainActor.run {
            self.weeklyActivities = dailyActivities.sorted { $0.date < $1.date }
        }
    }

    // MARK: - Fetch Specific Metrics
    private func fetchSteps(from startDate: Date, to endDate: Date) async -> Int {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepCountType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let steps = Int(sum.doubleValue(for: HKUnit.count()))
                continuation.resume(returning: steps)
            }
            healthStore.execute(query)
        }
    }

    private func fetchDistance(from startDate: Date, to endDate: Date) async -> Double {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: distanceType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0.0)
                    return
                }
                let miles = sum.doubleValue(for: HKUnit.mile())
                continuation.resume(returning: miles)
            }
            healthStore.execute(query)
        }
    }

    private func fetchExerciseMinutes(from startDate: Date, to endDate: Date) async -> Int {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: exerciseTimeType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: 0)
                    return
                }
                let minutes = Int(sum.doubleValue(for: HKUnit.minute()))
                continuation.resume(returning: minutes)
            }
            healthStore.execute(query)
        }
    }

    // MARK: - Mock Data (for development/testing)
    func useMockHealthData(stepGoal: Int = 8000) {
        // Today's steps - fixed value that doesn't change when goal changes
        // This simulates real step tracking where actual steps are measured, not calculated
        todaySteps = 4480 // Fixed at ~56% of default 8000 goal
        todayDistance = 2.1
        todayMinutesMoved = 35
        hasHealthAccess = true

        let calendar = Calendar.current
        weeklyActivities = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!

            // Use date as seed for consistent "random" values per day
            let daysSinceReferenceDate = Int(date.timeIntervalSinceReferenceDate / 86400)
            let pseudoRandom = Double((daysSinceReferenceDate * 9301 + 49297) % 233280) / 233280.0

            // Generate fixed step count per day (not relative to current goal)
            // Use user's goal as base with variance from 30% to 130% to simulate realistic activity
            let progress = 0.3 + (pseudoRandom * 1.0) // Scales from 0.3 to 1.3
            let steps = Int(Double(stepGoal) * progress) // Fixed steps for this day

            // Claimed window if goal was met
            let claimedWindow = steps >= stepGoal

            // Distance based on steps (roughly)
            let distance = Double(steps) / 2000.0 // ~2000 steps per mile

            // Minutes based on steps
            let minutes = steps / 150 // ~150 steps per minute of walking

            return DailyActivity(
                date: calendar.startOfDay(for: date),
                steps: steps,
                distance: distance,
                minutesMoved: minutes,
                claimedWindow: claimedWindow
            )
        }.sorted { $0.date < $1.date }
    }
}
