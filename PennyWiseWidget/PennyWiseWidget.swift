//
//  PennyWiseWidget.swift
//  PennyWiseWidget
//
//  Created by Devin Maleke on 22/09/26.
//

import SwiftUI
import WidgetKit

struct WidgetSnapshot: Codable, Equatable {
    var monthTitle: String
    var netText: String
    var spendText: String
    var incomeText: String
    var topExpenseName: String
    var topExpenseText: String
    var hasActivity: Bool
}

enum WidgetSnapshotReader {
    static let appGroupId = "group.com.custom.PennyWise"
    static let snapshotKey = "widget.snapshot"

    static func load() -> WidgetSnapshot? {
        guard
            let defaults = UserDefaults(suiteName: appGroupId),
            let data = defaults.data(forKey: snapshotKey)
        else {
            return nil
        }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}

struct PennyWiseEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct PennyWiseProvider: TimelineProvider {
    func placeholder(in context: Context) -> PennyWiseEntry {
        PennyWiseEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PennyWiseEntry) -> Void) {
        completion(PennyWiseEntry(date: Date(), snapshot: WidgetSnapshotReader.load() ?? .placeholder))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PennyWiseEntry>) -> Void) {
        let entry = PennyWiseEntry(date: Date(), snapshot: WidgetSnapshotReader.load())
        let nextUpdate = Calendar.current.nextDate(
            after: Date(),
            matching: DateComponents(hour: 0, minute: 5),
            matchingPolicy: .nextTime
        ) ?? Date().addingTimeInterval(60 * 60)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct PennyWiseWidgetEntryView: View {
    var entry: PennyWiseEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            if #available(iOS 17.0, *) {
                content
                    .padding(family == .systemSmall ? 12 : 16)
            } else {
                ZStack {
                    Color(red: 29 / 255, green: 46 / 255, blue: 62 / 255)
                    content
                        .padding(family == .systemSmall ? 12 : 16)
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .systemMedium:
                mediumView(snapshot)
            default:
                smallView(snapshot)
            }
        } else {
            emptyView
        }
    }

    private func smallView(_ snapshot: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("PennyWise")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            Text(snapshot.monthTitle)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
            Spacer(minLength: 0)
            Text(snapshot.hasActivity ? snapshot.netText : "No activity")
                .font(.headline)
                .bold()
                .foregroundColor(.white)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text("Net")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private func mediumView(_ snapshot: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("PennyWise")
                    .font(.caption)
                    .bold()
                Spacer()
                Text(snapshot.monthTitle)
                    .font(.caption)
            }
            .foregroundColor(.white.opacity(0.9))

            if snapshot.hasActivity {
                Text(snapshot.netText)
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                HStack(spacing: 16) {
                    metric(title: "Spent", value: snapshot.spendText, color: Color(red: 231 / 255, green: 76 / 255, blue: 60 / 255))
                    metric(title: "Income", value: snapshot.incomeText, color: Color(red: 39 / 255, green: 174 / 255, blue: 96 / 255))
                }

                if !snapshot.topExpenseName.isEmpty {
                    Text("Top \(snapshot.topExpenseName)  \(snapshot.topExpenseText)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                }
            } else {
                Spacer(minLength: 0)
                Text("No activity this month")
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text("Open PennyWise to add a transaction")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                Spacer(minLength: 0)
            }
        }
    }

    private func metric(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.subheadline)
                .bold()
                .foregroundColor(color)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("PennyWise")
                .font(.caption)
                .bold()
                .foregroundColor(.white)
            Spacer(minLength: 0)
            Text("Open the app to see this month")
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
            Spacer(minLength: 0)
        }
    }
}

@main
struct PennyWiseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "PennyWiseThisMonth", provider: PennyWiseProvider()) { entry in
            if #available(iOS 17.0, *) {
                PennyWiseWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color(red: 29 / 255, green: 46 / 255, blue: 62 / 255)
                    }
            } else {
                PennyWiseWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("This month")
        .description("Net, spend, and income for the current month.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

private extension WidgetSnapshot {
    static let placeholder = WidgetSnapshot(
        monthTitle: "September 2026",
        netText: "Rp 1.250.000",
        spendText: "- Rp 750.000",
        incomeText: "+ Rp 2.000.000",
        topExpenseName: "Food",
        topExpenseText: "Rp 320.000",
        hasActivity: true
    )
}
