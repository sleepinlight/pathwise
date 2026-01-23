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
    func useMockHealthData() {
        todaySteps = 4532
        todayDistance = 2.1
        todayMinutesMoved = 35
        hasHealthAccess = true

        let calendar = Calendar.current
        weeklyActivities = (0..<7).map { dayOffset in
            let date = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            return DailyActivity(
                date: calendar.startOfDay(for: date),
                steps: Int.random(in: 3000...9000),
                distance: Double.random(in: 1.5...4.5),
                minutesMoved: Int.random(in: 20...60),
                claimedWindow: Bool.random()
            )
        }.sorted { $0.date < $1.date }
    }
}
