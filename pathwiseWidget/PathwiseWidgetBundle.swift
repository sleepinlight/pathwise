//
//  PathwiseWidgetBundle.swift
//  pathwise
//
//  Widget bundle for all Pathwise widgets
//

import WidgetKit
import SwiftUI

struct TestMinimalEntry: TimelineEntry {
    let date: Date
}

struct TestMinimalProvider: TimelineProvider {
    func placeholder(in context: Context) -> TestMinimalEntry {
        TestMinimalEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (TestMinimalEntry) -> Void) {
        completion(TestMinimalEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TestMinimalEntry>) -> Void) {
        let entry = TestMinimalEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct TestMinimalWidgetView: View {
    var entry: TestMinimalEntry
    var body: some View {
        ZStack {
            Color.blue.opacity(0.15)
            VStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.blue)
                Text("Pathwise Test")
                    .font(.caption)
                    .foregroundStyle(.primary)
            }
            .padding()
        }
    }
}

struct TestMinimalWidget: Widget {
    let kind: String = "TestMinimalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TestMinimalProvider()) { entry in
            TestMinimalWidgetView(entry: entry)
        }
        .configurationDisplayName("Pathwise Test")
        .description("A minimal test widget to verify registration.")
        .supportedFamilies([.systemSmall])
    }
}

@main
struct PathwiseWidgetBundle: WidgetBundle {
    var body: some Widget {
        TestMinimalWidget()
    }
}
