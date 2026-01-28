//
//  HealthKitService.swift
//  pathwise
//
//  Service for accessing HealthKit data
//

import Foundation
import HealthKit

actor HealthKitService {
    private let healthStore = HKHealthStore()

    /// Fetches the user's average walking speed from outdoor walking workouts
    /// - Returns: Average walking speed in miles per hour, or nil if unavailable
    func fetchAverageWalkingSpeed() async -> Double? {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚕️ HealthKit not available on this device")
            return nil
        }

        // Request authorization for walking/running workouts and distance
        let workoutType = HKObjectType.workoutType()
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!

        do {
            try await healthStore.requestAuthorization(toShare: [], read: [workoutType, distanceType])
        } catch {
            print("⚕️ HealthKit authorization failed: \(error)")
            return nil
        }

        // Query for outdoor walking workouts from the last 60 days
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -60, to: endDate)!

        let workoutPredicate = HKQuery.predicateForWorkouts(with: .walking)
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [workoutPredicate, datePredicate])

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: workoutType,
                predicate: compoundPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]
            ) { _, samples, error in
                if let error = error {
                    print("⚕️ HealthKit query error: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let workouts = samples as? [HKWorkout], !workouts.isEmpty else {
                    print("⚕️ No walking workout data available")
                    continuation.resume(returning: nil)
                    return
                }

                // Filter for outdoor workouts and calculate average pace
                let outdoorWorkouts = workouts.filter { workout in
                    // Only include outdoor walking workouts with sufficient distance
                    let isOutdoor = workout.workoutActivityType == .walking
                    let hasDistance = (workout.totalDistance?.doubleValue(for: .mile()) ?? 0) > 0.1
                    let hasDuration = workout.duration > 60 // At least 1 minute
                    return isOutdoor && hasDistance && hasDuration
                }

                guard !outdoorWorkouts.isEmpty else {
                    print("⚕️ No outdoor walking workouts found")
                    continuation.resume(returning: nil)
                    return
                }

                // Calculate average speed from workouts
                var totalSpeed = 0.0
                var count = 0

                for workout in outdoorWorkouts.prefix(10) { // Use last 10 workouts
                    if let distance = workout.totalDistance?.doubleValue(for: .mile()),
                       workout.duration > 0 {
                        let hours = workout.duration / 3600.0
                        let speed = distance / hours
                        totalSpeed += speed
                        count += 1
                    }
                }

                guard count > 0 else {
                    print("⚕️ Could not calculate average pace")
                    continuation.resume(returning: nil)
                    return
                }

                let averageSpeed = totalSpeed / Double(count)
                print("⚕️ Average exercise walking speed: \(averageSpeed) mph (\(60.0 / averageSpeed) min/mile) from \(count) workouts")
                continuation.resume(returning: averageSpeed)
            }

            healthStore.execute(query)
        }
    }

    /// Calculates estimated walking time based on distance and user's pace
    /// - Parameters:
    ///   - distance: Distance in miles
    ///   - userSpeed: User's average walking speed in mph (optional)
    /// - Returns: Estimated time in minutes
    func calculateWalkingTime(distance: Double, userSpeed: Double?) -> Double {
        let speed = userSpeed ?? 3.0 // Default: 3 mph (20 min/mile) if no HealthKit data
        let hours = distance / speed
        return hours * 60.0 // Convert to minutes
    }
}
