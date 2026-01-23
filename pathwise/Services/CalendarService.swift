//
//  CalendarService.swift
//  pathwise
//
//  Calendar integration using EventKit
//

import Foundation
import EventKit
import Combine

class CalendarService: ObservableObject {
    private let eventStore = EKEventStore()

    @Published var hasCalendarAccess = false
    @Published var events: [CalendarEvent] = []
    @Published var freeBlocks: [FreeTimeBlock] = []

    // MARK: - Authorization
    func requestCalendarAccess() async -> Bool {
        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            await MainActor.run {
                self.hasCalendarAccess = granted
            }
            return granted
        } catch {
            print("Calendar access error: \(error)")
            return false
        }
    }

    // MARK: - Fetch Events
    func fetchTodayEvents() async {
        guard hasCalendarAccess else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let predicate = eventStore.predicateForEvents(
            withStart: startOfDay,
            end: endOfDay,
            calendars: nil
        )

        let ekEvents = eventStore.events(matching: predicate)

        let calendarEvents = ekEvents.map { event in
            CalendarEvent(
                title: event.title ?? "Untitled",
                startTime: event.startDate,
                endTime: event.endDate,
                isAllDay: event.isAllDay
            )
        }

        await MainActor.run {
            self.events = calendarEvents
            self.freeBlocks = calculateFreeBlocks(from: calendarEvents)
        }
    }

    // MARK: - Calculate Free Time Blocks
    private func calculateFreeBlocks(from events: [CalendarEvent]) -> [FreeTimeBlock] {
        let calendar = Calendar.current
        let now = Date()

        // Define working hours (6 AM to 10 PM)
        let startHour = 6
        let endHour = 22

        guard let dayStart = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: now),
              let dayEnd = calendar.date(bySettingHour: endHour, minute: 0, second: 0, of: now) else {
            return []
        }

        // Filter and sort non-all-day events
        let sortedEvents = events
            .filter { !$0.isAllDay && $0.endTime > now }
            .sorted { $0.startTime < $1.startTime }

        var freeBlocks: [FreeTimeBlock] = []
        var currentTime = max(now, dayStart)

        // Find gaps between events
        for event in sortedEvents {
            if event.startTime > currentTime {
                // There's a gap before this event
                let freeBlock = FreeTimeBlock(
                    startTime: currentTime,
                    endTime: event.startTime
                )
                // Only include blocks that are at least 30 minutes
                if freeBlock.durationInMinutes >= 30 {
                    freeBlocks.append(freeBlock)
                }
            }
            currentTime = max(currentTime, event.endTime)
        }

        // Add final block from last event to end of day
        if currentTime < dayEnd {
            let freeBlock = FreeTimeBlock(
                startTime: currentTime,
                endTime: dayEnd
            )
            if freeBlock.durationInMinutes >= 30 {
                freeBlocks.append(freeBlock)
            }
        }

        return freeBlocks
    }

    // MARK: - Mock Data (for development/testing)
    func useMockCalendar() {
        let calendar = Calendar.current
        let now = Date()

        // Create some mock events
        let mockEvents: [CalendarEvent] = [
            CalendarEvent(
                title: "Morning Meeting",
                startTime: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now)!,
                endTime: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now)!,
                isAllDay: false
            ),
            CalendarEvent(
                title: "Lunch",
                startTime: calendar.date(bySettingHour: 12, minute: 0, second: 0, of: now)!,
                endTime: calendar.date(bySettingHour: 13, minute: 0, second: 0, of: now)!,
                isAllDay: false
            ),
            CalendarEvent(
                title: "Marketing Sync",
                startTime: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: now)!,
                endTime: calendar.date(bySettingHour: 15, minute: 30, second: 0, of: now)!,
                isAllDay: false
            ),
            CalendarEvent(
                title: "Project Review",
                startTime: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: now)!,
                endTime: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now)!,
                isAllDay: false
            )
        ]

        self.events = mockEvents
        self.freeBlocks = calculateFreeBlocks(from: mockEvents)
        self.hasCalendarAccess = true
    }
}
