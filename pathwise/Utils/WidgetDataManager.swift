//
//  PathwiseWidgetDataManager.swift
//  pathwise
//
//  Manages shared data between the main app and widgets using App Groups
//

import Foundation
import WidgetKit

// MARK: - Widget Data Model

struct PathwiseWidgetData: Codable {
    let goldenWindow: GoldenWindow?
    let additionalWindows: [GoldenWindow]
    let fallbackWindow: GoldenWindow?
    let noWindowReason: NoWindowReason?
    let todaySteps: Int
    let stepGoal: Int
    let isInGoldenWindow: Bool
    let theme: AppTheme
    let darkModeStyle: DarkModeStyle
    let lastUpdated: Date
}

// MARK: - Shared Data Manager

class PathwiseWidgetDataManager {
    static let shared = PathwiseWidgetDataManager()

    // IMPORTANT: Replace this with your actual App Group identifier
    // Format: group.com.yourcompany.pathwise
    private let appGroupIdentifier = "group.com.pathwise.app"
    private let widgetDataKey = "pathwise.widget.data"

    private var sharedDefaults: UserDefaults? {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ Failed to create UserDefaults suite for: \(appGroupIdentifier)")
            return nil
        }
        print("✅ Successfully created UserDefaults suite for: \(appGroupIdentifier)")
        return defaults
    }

    private init() {}

    // MARK: - Save Data

    func savePathwiseWidgetData(_ data: PathwiseWidgetData) {
        guard let defaults = sharedDefaults else {
            print("❌ Failed to access App Group UserDefaults")
            return
        }

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let encodedData = try encoder.encode(data)
            defaults.set(encodedData, forKey: widgetDataKey)
            // Note: synchronize() is deprecated and unnecessary - UserDefaults auto-saves

            // Tell widgets to reload their timelines
            WidgetCenter.shared.reloadAllTimelines()

            print("✅ Widget data saved successfully")
        } catch {
            print("❌ Failed to encode widget data: \(error)")
        }
    }

    // MARK: - Load Data

    func loadPathwiseWidgetData() -> PathwiseWidgetData? {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: widgetDataKey) else {
            print("⚠️ No widget data found in App Group")
            return nil
        }

        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let widgetData = try decoder.decode(PathwiseWidgetData.self, from: data)
            print("✅ Widget data loaded successfully")
            return widgetData
        } catch {
            print("❌ Failed to decode widget data: \(error)")
            return nil
        }
    }

    // MARK: - Clear Data

    func clearPathwiseWidgetData() {
        guard let defaults = sharedDefaults else { return }
        defaults.removeObject(forKey: widgetDataKey)
        WidgetCenter.shared.reloadAllTimelines()
        print("🗑️ Widget data cleared")
    }

    // MARK: - Helper: Create Widget Data from Current State

    static func createPathwiseWidgetData(
        goldenWindow: GoldenWindow?,
        additionalWindows: [GoldenWindow] = [],
        fallbackWindow: GoldenWindow? = nil,
        noWindowReason: NoWindowReason? = nil,
        todaySteps: Int,
        stepGoal: Int,
        isInGoldenWindow: Bool,
        theme: AppTheme = .system,
        darkModeStyle: DarkModeStyle = .default
    ) -> PathwiseWidgetData {
        return PathwiseWidgetData(
            goldenWindow: goldenWindow,
            additionalWindows: additionalWindows,
            fallbackWindow: fallbackWindow,
            noWindowReason: noWindowReason,
            todaySteps: todaySteps,
            stepGoal: stepGoal,
            isInGoldenWindow: isInGoldenWindow,
            theme: theme,
            darkModeStyle: darkModeStyle,
            lastUpdated: Date()
        )
    }
}
