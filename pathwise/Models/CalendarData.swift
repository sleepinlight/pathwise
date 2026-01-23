//
//  CalendarData.swift
//  pathwise
//
//  Calendar and scheduling models
//

import Foundation

struct CalendarEvent: Identifiable {
    let id = UUID()
    let title: String
    let startTime: Date
    let endTime: Date
    let isAllDay: Bool

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

struct FreeTimeBlock: Identifiable {
    let id = UUID()
    let startTime: Date
    let endTime: Date

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var durationInMinutes: Int {
        Int(duration / 60)
    }

    func contains(date: Date) -> Bool {
        date >= startTime && date <= endTime
    }
}
