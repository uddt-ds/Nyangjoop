//
//  NyangjoopWidget.swift
//  NyangjoopWidget
//
//  Created by Lee on 12/6/25.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), stats: WidgetStats(catCount: 0, visitCount: 0, medalCount: 0))
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let stats = SharedDataManager.loadWidgetStats()
        let entry = SimpleEntry(date: Date(), stats: stats)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let stats = SharedDataManager.loadWidgetStats()
        let entry = SimpleEntry(date: Date(), stats: stats)

        // 앱에서 실시간 업데이트하므로 자동 갱신 불필요
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let stats: WidgetStats
}

struct NyangjoopWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(stats: entry.stats)
            case .systemMedium, .systemLarge:
                MediumWidgetView(stats: entry.stats)
            default:
                SmallWidgetView(stats: entry.stats)
            }
        }
        .unredacted()
    }
}

struct SmallWidgetView: View {
    let stats: WidgetStats

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(.widgetNyang)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                Text("\(stats.catCount)")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.black)
            }

            HStack(spacing: 4) {
                Image(.widgetCamera)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                Text("\(stats.visitCount)")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.black)
            }

            HStack(spacing: 4) {
                Image(.widgetMedal)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20)
                Text("\(stats.medalCount)")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.black)
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.appBg)
        )
    }
}

struct MediumWidgetView: View {
    let stats: WidgetStats

    var body: some View {
        HStack(spacing: 20) {
            VStack(spacing: 8) {
                Image(.widgetNyang)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                Text("\(stats.catCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }

            VStack(spacing: 8) {
                Image(.widgetCamera)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                Text("\(stats.visitCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }

            VStack(spacing: 8) {
                Image(.widgetMedal)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
                Text("\(stats.medalCount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(.appBg)
        )
    }
}

struct NyangjoopWidget: Widget {
    let kind: String = "NyangjoopWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                NyangjoopWidgetEntryView(entry: entry)
                    .containerBackground(.key, for: .widget)
            } else {
                NyangjoopWidgetEntryView(entry: entry)
            }
        }
        .configurationDisplayName("냥냥 통계")
        .description("등록한 고양이, 방문 기록, 획득 메달을 확인하세요.")
    }
}

#Preview(as: .systemSmall) {
    NyangjoopWidget()
} timeline: {
    SimpleEntry(date: .now, stats: WidgetStats(catCount: 5, visitCount: 12, medalCount: 3))
    SimpleEntry(date: .now, stats: WidgetStats(catCount: 10, visitCount: 25, medalCount: 7))
}
