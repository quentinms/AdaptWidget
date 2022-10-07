//
//  AWidget.swift
//  AWidget
//
//  Created by Quentin Mazars-Simon on 10/7/22.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), data: AdaptData(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), data: AdaptData(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, data: AdaptData(), configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let data: AdaptData
    let configuration: ConfigurationIntent
    
    let now: NowEntry
    let nextLow: NowEntry
    let forecast: [NowEntry]
    
    init(date: Date, data: AdaptData, configuration: ConfigurationIntent) {
        self.date = date
        self.data = data
        self.configuration = configuration
        self.now = NowEntry(data: data.forecast[0])
        self.nextLow = NowEntry(data: data.nextLow)
        self.forecast = data.forecast.map{NowEntry(data: $0)}
    }
}

struct NowEntry {
    let data: AdaptForecast
    let text: String
    let imageName: String
    let imageTint : Color
    
    init(data: AdaptForecast) {
        self.data = data
        // YOLO/TODO
        switch data.level {
        case 1:
            self.text = "très peu carbonée"
            self.imageName = "1.circle"
            self.imageTint = Color(red:234/255, green:69/255, blue: 34/255)
        case 2:
            self.text = "peu carbonée"
            self.imageName = "2.circle"
            self.imageTint = Color(red:52/255, green:188/255, blue: 110/255)
        case 3:
            self.text = "modérement carbonée"
            self.imageName = "3.circle"
            self.imageTint = Color(red:255/255, green:206/255, blue: 0/255)
        case 4:
            self.text = "très carbonée"
            self.imageName = "4.circle"
            self.imageTint = Color(red:234/255, green:69/255, blue: 34/255)
        case 5:
            self.text = "extrêmement carbonée"
            self.imageName = "5.circle"
            self.imageTint = Color(red:170/255, green:12/255, blue: 64/255)
        default:
            self.text = "🤷‍♂️"
            self.imageName = "1"
            self.imageTint = Color(red:252/255, green:158/255, blue: 158/255)
        }
    }
}

struct AdaptData {
    let nextLow: AdaptForecast
    let forecast: [AdaptForecast]
    
    init() { // placeholder
        self.nextLow = AdaptForecast(date: Date().addingTimeInterval(8*3600), level: 2)
        self.forecast = [
            AdaptForecast(date: Date(), level: 5),
            AdaptForecast(date: Date().addingTimeInterval(3600), level: 4),
            AdaptForecast(date: Date().addingTimeInterval(2*3600), level: 3),
            AdaptForecast(date: Date().addingTimeInterval(3*3600), level: 2),
            AdaptForecast(date: Date().addingTimeInterval(4*3600), level: 1),
            AdaptForecast(date: Date().addingTimeInterval(5*3600), level: 5),
        ]
    }
}

struct AdaptForecast {
    let date: Date
    let level: UInt8
}

//extension Date {
//        func formatHour() -> String {
//            let dateFormatter = DateFormatter()
//            dateFormatter.setLocalizedDateFormatFromTemplate("j")
//            dateFormatter.locale = Locale(identifier: "fr")
//            return dateFormatter.string(from: self)
//        }
//
//     func formatDay() -> String {
//        let dateFormatter = DateFormatter()
//        dateFormatter.setLocalizedDateFormatFromTemplate("E dd")
//        dateFormatter.locale = Locale(identifier: "fr")
//        return dateFormatter.string(from: self)
//    }
//}

struct AWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                Spacer()
                VStack(alignment: .center) {
                    Text(entry.now.text.capitalized(with: Locale.current)).bold()
                        
                    Image( systemName: entry.now.imageName).resizable(resizingMode: .stretch).foregroundColor(entry.now.imageTint).frame(width:30, height:30, alignment: Alignment.center)
                }
                Spacer()
                VStack(alignment: .center) {
                    HStack {
                        Text("Prochain").bold()
                        Image(systemName: entry.nextLow.imageName).foregroundColor(entry.nextLow.imageTint)
                    }
                    Text(entry.nextLow.data.date, format:Date.FormatStyle().weekday().day().hour())
                }
                Spacer()
            }
            HStack(alignment: .top) {
                ForEach(entry.forecast, id: \.data.date) { f in
                    Spacer()
                    VStack {
                        Text(f.data.date, format:Date.FormatStyle().hour())
                        Image(systemName:f.imageName).foregroundColor(f.imageTint).frame(width:10, height:10, alignment: Alignment.center)
                    }
                }
                Spacer()
            }
        }
    }
}

@main
struct AWidget: Widget {
    let kind: String = "AWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            AWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct AWidget_Previews: PreviewProvider {
    static var previews: some View {
        AWidgetEntryView(entry: SimpleEntry(date: Date(), data: AdaptData(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
