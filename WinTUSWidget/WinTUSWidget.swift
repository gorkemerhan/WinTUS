import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), emoji: "📚")
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), emoji: "📚")
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        // Basit bir timeline: Şu anki zaman
        let currentDate = Date()
        let entry = SimpleEntry(date: currentDate, emoji: "📚")
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let emoji: String
}

struct WinTUSWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            Text("WinTUS")
                .font(.headline)
            Text(entry.emoji)
                .font(.largeTitle)
            Text("Çalışmaya Başla!")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct WinTUSWidget: Widget {
    let kind: String = "WinTUSWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                WinTUSWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WinTUSWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("WinTUS Kısayol")
        .description("Hızlıca ders çalışmaya başlayın.")
    }
}
