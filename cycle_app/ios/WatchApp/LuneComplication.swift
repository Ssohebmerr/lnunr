import WidgetKit
import SwiftUI

struct LuneComplicationProvider: TimelineProvider {
    func placeholder(in context: Context) -> LuneEntry {
        LuneEntry(date: Date(), day: 14, maxDays: 28, phase: "Luteal")
    }

    func getSnapshot(in context: Context, completion: @escaping (LuneEntry) -> Void) {
        let entry = LuneEntry(date: Date(), day: 14, maxDays: 28, phase: "Luteal")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        let defaults = UserDefaults.standard
        let day = defaults.integer(forKey: "cycleDay")
        let max = defaults.integer(forKey: "cycleMax")
        let phase = defaults.string(forKey: "cyclePhase") ?? "Unknown"
        let entry = LuneEntry(date: Date(), day: day, maxDays: Swift.max(max, 1), phase: phase)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct LuneEntry: TimelineEntry {
    let date: Date
    let day: Int
    let maxDays: Int
    let phase: String

    var progress: Double {
        guard maxDays > 0 else { return 0 }
        return Double(day) / Double(maxDays)
    }
}

struct LuneComplicationEntryView: View {
    var entry: LuneEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                Gauge(value: entry.progress) {
                    Text("\(entry.day)")
                        .font(.system(size: 16, weight: .bold))
                }
                .gaugeStyle(.accessoryCircular)
                .tint(phaseColor(entry.phase))
            }
        case .accessoryRectangular:
            HStack {
                VStack(alignment: .leading) {
                    Text("Lune")
                        .font(.system(size: 10, weight: .semibold))
                    Text("Day \(entry.day) / \(entry.maxDays)")
                        .font(.system(size: 14, weight: .bold))
                    Text(entry.phase)
                        .font(.system(size: 10))
                        .foregroundColor(phaseColor(entry.phase))
                }
                Spacer()
            }
        default:
            Text("Lune")
        }
    }

    func phaseColor(_ phase: String) -> Color {
        switch phase.lowercased() {
        case "menstruation", "period":
            return .pink
        case "follicular":
            return .purple
        case "ovulation":
            return .orange
        case "luteal":
            return .blue
        default:
            return .green
        }
    }
}

@main
struct LuneComplication: Widget {
    let kind: String = "LuneComplication"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LuneComplicationProvider()) { entry in
            LuneComplicationEntryView(entry: entry)
        }
        .configurationDisplayName("Lune")
        .description("Track your cycle at a glance")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}
