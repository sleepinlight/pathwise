//
//  WidgetSupport.swift
//  pathwise
//
//  Shared data models and helpers for widget support
//

import Foundation
import WidgetKit

// MARK: - Widget Data Model
struct WidgetData: Codable {
    let goldenWindow: GoldenWindow?
    let todaySteps: Int
    let lastUpdated: Date

    static var placeholder: WidgetData {
        WidgetData(
            goldenWindow: GoldenWindow(
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
                reasonSummary: "Perfect conditions",
                locationName: "San Francisco, CA"
            ),
            todaySteps: 5432,
            lastUpdated: Date()
        )
    }
}

// MARK: - App Group Support
extension FileManager {
    static let appGroupIdentifier = "group.com.pathwise.app"

    static func sharedContainerURL() -> URL? {
        return FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )
    }

    static func widgetDataURL() -> URL? {
        return sharedContainerURL()?.appendingPathComponent("widgetData.json")
    }
}

// MARK: - Widget Data Manager
class WidgetDataManager {
    static let shared = WidgetDataManager()

    private init() {}

    func saveWidgetData(_ data: WidgetData) {
        guard let url = FileManager.widgetDataURL() else { return }

        do {
            let jsonData = try JSONEncoder().encode(data)
            try jsonData.write(to: url, options: .atomic)
            WidgetCenter.shared.reloadAllTimelines()
        } catch {
            print("Error saving widget data: \(error)")
        }
    }

    func loadWidgetData() -> WidgetData? {
        guard let url = FileManager.widgetDataURL() else { return nil }

        do {
            let jsonData = try Data(contentsOf: url)
            return try JSONDecoder().decode(WidgetData.self, from: jsonData)
        } catch {
            print("Error loading widget data: \(error)")
            return nil
        }
    }
}

// Note: In a production app, you would create a separate Widget Extension target
// For Phase 1, this file provides the infrastructure needed for widget support
// To add widgets:
// 1. Create a Widget Extension target in Xcode
// 2. Add an App Group capability to both app and widget targets
// 3. Implement the widget views using SwiftUI
// 4. Use WidgetDataManager to share data between app and widgets
