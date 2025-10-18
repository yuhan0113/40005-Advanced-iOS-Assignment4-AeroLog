//
//  AeroLogWidget.swift
//  AeroLogWidget
//
//  Created by 張宇漢 on 18/10/2025.
//

import WidgetKit
import SwiftUI
import CoreData

struct AeroLogWidget: Widget {
    let kind: String = "AeroLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AeroLogWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Flight Tracker")
        .description("View your upcoming flights and travel tasks.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            upcomingFlights: [
                FlightInfo(
                    flightNumber: "QF123",
                    departure: "SYD",
                    arrival: "MEL",
                    departureTime: "14:30",
                    airline: "Qantas"
                )
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(
            date: Date(),
            upcomingFlights: fetchUpcomingFlights()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = SimpleEntry(
            date: currentDate,
            upcomingFlights: fetchUpcomingFlights()
        )
        
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func fetchUpcomingFlights() -> [FlightInfo] {
        return WidgetDataManager.shared.fetchUpcomingFlights(limit: 3)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let upcomingFlights: [FlightInfo]
}


struct AeroLogWidgetEntryView: View {
    var entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "airplane")
                    .foregroundColor(.blue)
                Text("AeroLog")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            
            if entry.upcomingFlights.isEmpty {
                VStack {
                    Image(systemName: "airplane.departure")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("No upcoming flights")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ForEach(Array(entry.upcomingFlights.enumerated()), id: \.offset) { index, flight in
                    FlightRowView(flight: flight)
                        .widgetURL(URL(string: "aerolog://flight/\(flight.flightNumber)"))
                    if index < entry.upcomingFlights.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "aerolog://add-flight"))
    }
}

struct FlightRowView: View {
    let flight: FlightInfo
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(flight.flightNumber)
                    .font(.caption)
                    .fontWeight(.semibold)
                Text("\(flight.departure) → \(flight.arrival)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(flight.departureTime)
                    .font(.caption)
                    .fontWeight(.medium)
                Text(flight.airline)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview(as: .systemSmall) {
    AeroLogWidget()
} timeline: {
    SimpleEntry(
        date: .now,
        upcomingFlights: [
            FlightInfo(
                flightNumber: "QF123",
                departure: "SYD",
                arrival: "MEL",
                departureTime: "14:30",
                airline: "Qantas"
            ),
            FlightInfo(
                flightNumber: "VA456",
                departure: "MEL",
                arrival: "BNE",
                departureTime: "18:45",
                airline: "Virgin Australia"
            )
        ]
    )
}
