//
//  ZZZWidget.swift
//  ZZZWidget
//
//  Created by Joo on 1/7/26.
//

import WidgetKit
import SwiftUI

struct ZZZWidgetEntry: TimelineEntry {
    let date: Date
    let title: String
    let status: String
    let updatedAt: String
}

struct ZZZWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ZZZWidgetEntry {
        ZZZWidgetEntry(date: Date(), title: "My Partner", status: "Waiting...", updatedAt: "Just now")
    }

    func getSnapshot(in context: Context, completion: @escaping (ZZZWidgetEntry) -> ()) {
        let data = getData()
        let entry = ZZZWidgetEntry(date: Date(), title: data.title, status: data.status, updatedAt: data.updatedAt)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ZZZWidgetEntry>) -> ()) {
        let data = getData()
        let entry = ZZZWidgetEntry(date: Date(), title: data.title, status: data.status, updatedAt: data.updatedAt)
        
        // Refresh every 15 minutes roughly, but mostly reliant on app pushes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func getData() -> (title: String, status: String, updatedAt: String) {
        let userDefaults = UserDefaults(suiteName: "group.com.joo.zzz")
        let title = userDefaults?.string(forKey: "title") ?? "My Partner"
        let status = userDefaults?.string(forKey: "status") ?? "No Status"
        let updatedAt = userDefaults?.string(forKey: "updatedAt") ?? ""
        return (title, status, updatedAt)
    }
}

struct ZZZWidgetEntryView : View {
    var entry: ZZZWidgetProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.title)
                .font(.headline)
                .bold()
            
            Text(entry.status)
                .font(.title2)
                .foregroundColor(.blue) // Simple styling, can be improved
            
            if !entry.updatedAt.isEmpty {
                Text(entry.updatedAt)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

struct ZZZWidget: Widget {
    let kind: String = "ZZZWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ZZZWidgetProvider()) { entry in
            ZZZWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Partner Status")
        .description("See your partner's current status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    ZZZWidget()
} timeline: {
    ZZZWidgetEntry(date: Date(), title: "Joo", status: "Sleeping 😴", updatedAt: "10 min ago")
    ZZZWidgetEntry(date: Date(), title: "Joo", status: "Studying 📚", updatedAt: "1 hour ago")
}