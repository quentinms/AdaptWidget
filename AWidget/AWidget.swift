//
//  AWidget.swift
//  AWidget
//
//  Created by Quentin Mazars-Simon on 10/7/22.
//

// Following this tutorial: https://schwiftyui.com/swiftui/building-a-widget-for-ios-with-swiftui-and-widgetkit/

import WidgetKit
import SwiftUI
import Intents

enum AdaptDataResponse {
    case Success(data: AdaptData)
    case Failure
}

struct AdaptApiResponse: Decodable {
    var status: String
    var version: String
    var forecasts: [ApiForecast]
}

struct ApiForecast: Decodable {
    var start: Date
    var end: Date
    var location: String
    var levelScore: UInt8
    var carbonIntensity: UInt32
}

enum Location : Int {
    case defaut = 0
    case franceContinentale = 1
    case belgium = 2
    case germany = 3
    case austria = 4
    case italia = 5
    case netherlands = 6
    case spain = 7
    case switzerland = 8
    case guadeloupe = 9
    case unitedKingdom = 10
}

extension Location {
    var short: String {
        switch self {
        case .franceContinentale:
            return "fr"
        case .belgium:
            return "be"
        case .germany:
            return "de"
        case .austria:
            return "at"
        case .italia:
            return "it"
        case .netherlands:
            return "nl"
        case .spain:
            return "es"
        case .switzerland:
            return "ch"
        case .guadeloupe:
            return "gp"
        case .unitedKingdom:
            return "uk"
        default:
            return "fr"
        }
    }
    
    var long: String {
        switch self {
        case .franceContinentale:
            return "france continentale"
        case .belgium:
            return "belgique"
        case .germany:
            return "deutschland"
        case .austria:
            return "österreich"
        case .italia:
            return "italia"
        case .netherlands:
            return "nederlanden"
        case .spain:
            return "españa"
        case .switzerland:
            return "suisse"
        case .guadeloupe:
            return "guadeloupe"
        case .unitedKingdom:
            return "united kingdom"
        default:
            return "france continentale"
        }
    }
}

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), location: Location.franceContinentale, data: AdaptData(), configuration: ConfigurationIntent())
    }
    
    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), location: Location.franceContinentale, data: AdaptData(), configuration: configuration)
        completion(entry)
    }
    
    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        let location = Location(rawValue: configuration.Location.rawValue)!
        
        Provider.getForecastFromApi(location: location.short) { adaptApiResponse in
            var entries: [SimpleEntry] = []
            var entry: SimpleEntry
            var policy: TimelineReloadPolicy
            
            
            switch adaptApiResponse {
            case .Failure:
                entry = SimpleEntry(date: Date(), location: location, errored: true, configuration: configuration)
                policy = .after(Calendar.current.date(byAdding: .minute, value: 15, to: Date())!)
                break
            case .Success(let data):
                entry = SimpleEntry(date: Date(), location: location, data: data, configuration: configuration)
                policy = .after(Calendar.current.date(byAdding: .minute, value: 15, to: Date())!)
                break
            }
            
            entries.append(entry)
            let timeline = Timeline(entries: entries, policy: policy)
            completion(timeline)
        }
    }
    
    static func getForecastFromApi(location : String, completion: ((AdaptDataResponse) -> Void)?) {
        
        let ApiKey = ""
        
        let urlString = "https://www.adapt.sh/api/v2/forecasts?location=\(location)&limit=72"
        
        let url = URL(string: urlString)!
        var request = URLRequest(url: url)
        request.addValue(ApiKey, forHTTPHeaderField: "X-AUTH-TOKEN")
        
        
        let task = URLSession.shared.dataTask(with: request) { data, urlResponse, error in
            parseResponseAndGetForecast(data: data, urlResponse: urlResponse, error: error, completion: completion)
        }
        task.resume()
    }
    
    static func parseResponseAndGetForecast(data: Data?, urlResponse: URLResponse?, error: Error?, completion: ((AdaptDataResponse) -> Void)?) {
        
        guard error == nil, let content = data else {
            print("error getting data from API")
            let response = AdaptDataResponse.Failure
            completion?(response)
            return
        }
        
        var adaptApiResponse: AdaptApiResponse
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            adaptApiResponse = try decoder.decode(AdaptApiResponse.self, from: content)
        } catch {
            print("error parsing forecast from data")
            print(error)
            let response = AdaptDataResponse.Failure
            completion?(response)
            return
        }
        
        let response = AdaptDataResponse.Success(data: AdaptData(apiData: adaptApiResponse))
        completion?(response)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let errored: Bool
    let location: Location
    let data: AdaptData?
    
    let now: HourlyEntry?
    let nextLow: HourlyEntry?
    let forecast: [HourlyEntry]
    
    init(date: Date, location: Location, data: AdaptData, configuration: ConfigurationIntent) {
        self.date = date
        self.configuration = configuration
        self.errored = false
        self.location = location
        self.data = data
        
        self.now = HourlyEntry(data: data.forecast[0])
        self.nextLow = data.nextLow.map {HourlyEntry(data: $0)}
        self.forecast = data.forecast.map{HourlyEntry(data: $0)}
    }
    
    init(date: Date, location: Location, errored: Bool, configuration: ConfigurationIntent) {
        self.date = date
        self.configuration = configuration
        self.errored = errored
        self.location = location
        self.data = nil
        
        self.now = nil
        self.nextLow = nil
        self.forecast = []
    }
}

struct HourlyEntry {
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
            self.imageTint = Color(red:0/255, green:168/255, blue: 73/255)
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
            self.imageName = "exclamationmark.circle"
            self.imageTint = Color(red:252/255, green:158/255, blue: 158/255)
        }
    }
}

struct AdaptData {
    let nextLow: AdaptForecast?
    let forecast: [AdaptForecast]
    
    init() { // placeholder
        self.nextLow = AdaptForecast(date: Date().addingTimeInterval(8*3600), level: 2)
        self.forecast = [
            AdaptForecast(date: Date(), level: 3),
            AdaptForecast(date: Date().addingTimeInterval(3600), level: 4),
            AdaptForecast(date: Date().addingTimeInterval(2*3600), level: 3),
            AdaptForecast(date: Date().addingTimeInterval(3*3600), level: 2),
            AdaptForecast(date: Date().addingTimeInterval(4*3600), level: 1),
            AdaptForecast(date: Date().addingTimeInterval(5*3600), level: 5),
        ]
    }
    
    init(apiData: AdaptApiResponse) {
        
        self.nextLow = apiData.forecasts.first {
            $0.levelScore <= 2
        }.map {
            AdaptForecast(date: $0.start, level: $0.levelScore)
        }
        
        self.forecast = apiData.forecasts[0 ..< 6].map {
            AdaptForecast(date: $0.start, level: $0.levelScore)
        }
    }
}

struct AdaptForecast {
    let date: Date
    let level: UInt8
}

struct AWidgetEntryView : View {
    
    @Environment(\.widgetFamily) var family
    
    var entry: Provider.Entry
    
    var mediumView: some View {
        VStack {
            Spacer()
            HStack(alignment: .top) {
                Spacer()
                Image( systemName: entry.now!.imageName).resizable(resizingMode: .stretch).foregroundColor(entry.now!.imageTint).frame(width:40, height:40)
                VStack(alignment: .leading) {
                    Text(entry.location.long.capitalized(with: Locale.current)).lineLimit(1).font(Font.headline)
                    Text(entry.now!.text.capitalized(with: Locale.current)).font(Font.body)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    HStack {
                        Text("Prochain").font(Font.headline)
                        Image(systemName: entry.nextLow!.imageName).foregroundColor(entry.nextLow!.imageTint)
                    }
                    Text(entry.nextLow!.data.date, format:Date.FormatStyle().weekday().day().hour()).font(Font.subheadline)
                }
                Spacer()
            }
            Spacer()
            HStack(alignment: .top) {
                ForEach(entry.forecast, id: \.data.date) { f in
                    Spacer()
                    VStack(spacing: 1.0) {
                        Text(f.data.date, format:Date.FormatStyle().hour()).fontWeight(.light).font(Font.caption)
                        Image(systemName:f.imageName).resizable(resizingMode: .stretch).foregroundColor(f.imageTint).frame(width:30, height:30)
                    }
                }
                Spacer()
            }
            Spacer(minLength: 20)
        }
    }
    
    var smallView: some View {
        VStack {
            Text(entry.location.long.capitalized(with: Locale.current)).bold().lineLimit(1)
            HStack(alignment: .center) {
                Image( systemName: entry.now!.imageName).resizable(resizingMode: .stretch).foregroundColor(entry.now!.imageTint).frame(width:30, height:30, alignment: Alignment.center)
                
                Text(entry.now!.text.capitalized(with: Locale.current))
            }
            VStack {
                HStack {
                    Text("Prochain").bold()
                    Image(systemName: entry.nextLow!.imageName).foregroundColor(entry.nextLow!.imageTint)
                }
                Text(entry.nextLow!.data.date, format:Date.FormatStyle().weekday().day().hour())
            }
        }
    }
    
    var accCircularView: some View {
        Image( systemName: entry.now!.imageName).resizable(resizingMode: .stretch).foregroundColor(entry.now!.imageTint).frame(width:30, height:30, alignment: Alignment.center)
    }
    
    var accInlineView: some View {
        HStack {
            Image(systemName: entry.nextLow!.imageName).foregroundColor(entry.nextLow!.imageTint)
            Text(entry.nextLow!.data.date, format:Date.FormatStyle().weekday().day().hour())
        }
    }
    
    var body: some View {
        if (entry.errored) {
            Image(systemName: "exclamationmark.circle")
            Text("Une erreur est survenue")
        } else {
            switch family {
            case .systemMedium:
                mediumView
            case .systemSmall:
                smallView
//            case .accessoryCircular:
//                accCircularView
//            case .accessoryInline:
//                accInlineView
            default:
                mediumView
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
        .configurationDisplayName("Adapt")
        .description("Widget Adapt.sh")
    }
}

struct AWidget_Previews: PreviewProvider {
    static var previews: some View {
        AWidgetEntryView(entry: SimpleEntry(date: Date(), location: Location.franceContinentale, data: AdaptData(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
